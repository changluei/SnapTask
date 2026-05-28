package com.example.demo.snaptask;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class SnapTaskService {
    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    @Value("${snaptask.deepseek.api-key:}")
    private String deepSeekApiKey;

    @Value("${snaptask.deepseek.api-url:https://api.deepseek.com/chat/completions}")
    private String deepSeekApiUrl;

    public SnapTaskService(JdbcTemplate jdbc, ObjectMapper objectMapper) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }

    public ApiResponse<Map<String, Object>> register(Map<String, Object> body) {
        String username = text(body, "username");
        String password = text(body, "password");
        String confirmPassword = text(body, "confirmPassword");
        if (username.isEmpty()) {
            return ApiResponse.fail("用户名不能为空");
        }
        if (password.isEmpty()) {
            return ApiResponse.fail("密码不能为空");
        }
        if (!password.equals(confirmPassword)) {
            return ApiResponse.fail("两次密码必须一致");
        }
        Integer exists = jdbc.queryForObject("SELECT COUNT(*) FROM snap_user WHERE username = ?", Integer.class, username);
        if (exists != null && exists > 0) {
            return ApiResponse.fail("用户名已存在");
        }
        Long userId = insert("INSERT INTO snap_user(username, password) VALUES (?, ?)", username, password);
        return ApiResponse.ok(findUserById(userId));
    }

    public ApiResponse<Map<String, Object>> login(Map<String, Object> body) {
        String username = text(body, "username");
        String password = text(body, "password");
        if (username.isEmpty() || password.isEmpty()) {
            return ApiResponse.fail("用户名和密码不能为空");
        }
        List<Map<String, Object>> users = rows("SELECT id, username, password, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') createdAt FROM snap_user WHERE username = ?", username);
        if (users.isEmpty()) {
            return ApiResponse.fail("用户不存在");
        }
        Map<String, Object> user = users.get(0);
        if (!password.equals(String.valueOf(user.get("password")))) {
            return ApiResponse.fail("密码错误");
        }
        user.remove("password");
        return ApiResponse.ok(user);
    }

    public ApiResponse<Map<String, Object>> dashboard(long userId, String sortMode) {
        refreshOverdue(userId);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("todayCount", count("SELECT COUNT(*) FROM todo_task WHERE user_id=? AND DATE(deadline)=CURDATE() AND status <> '已完成'", userId));
        data.put("soonCount", count("SELECT COUNT(*) FROM todo_task WHERE user_id=? AND deadline BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 3 DAY) AND status <> '已完成'", userId));
        data.put("overdueCount", count("SELECT COUNT(*) FROM todo_task WHERE user_id=? AND status='已逾期'", userId));
        data.put("doneCount", count("SELECT COUNT(*) FROM todo_task WHERE user_id=? AND status='已完成'", userId));
        data.put("totalCount", count("SELECT COUNT(*) FROM todo_task WHERE user_id=?", userId));
        data.put("historyCount", count("SELECT COUNT(*) FROM ocr_record WHERE user_id=?", userId));
        data.put("recentTasks", todos(userId, "全部", 0, "全部", 5, sortMode).getData());
        return ApiResponse.ok(data);
    }

    public ApiResponse<List<Map<String, Object>>> courses(long userId) {
        return ApiResponse.ok(rows("SELECT id, user_id userId, course_name courseName, teacher_name teacherName, color, remark, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') createdAt, DATE_FORMAT(updated_at, '%Y-%m-%d %H:%i') updatedAt FROM course WHERE user_id=? ORDER BY created_at DESC", userId));
    }

    public ApiResponse<Map<String, Object>> saveCourse(Map<String, Object> body) {
        long userId = longValue(body, "userId");
        String name = text(body, "courseName");
        if (userId <= 0 || name.isEmpty()) {
            return ApiResponse.fail("课程名称不能为空");
        }
        Long courseId = ensureCourse(userId, name, text(body, "teacherName"), text(body, "remark"));
        return ApiResponse.ok(courseById(courseId, userId));
    }

    public ApiResponse<List<Map<String, Object>>> todos(long userId, String status, long courseId, String priority, int limit, String sortMode) {
        refreshOverdue(userId);
        StringBuilder sql = new StringBuilder(todoSelectSql());
        List<Object> args = new ArrayList<>();
        sql.append(" WHERE t.user_id=?");
        args.add(userId);
        if (status != null && !status.equals("全部") && !status.isEmpty()) {
            sql.append(" AND t.status=?");
            args.add(status);
        }
        if (courseId > 0) {
            sql.append(" AND t.course_id=?");
            args.add(courseId);
        }
        if (priority != null && !priority.equals("全部") && !priority.isEmpty()) {
            sql.append(" AND t.priority=?");
            args.add(priority);
        }
        sql.append(orderBy(sortMode));
        if (limit > 0) {
            sql.append(" LIMIT ?");
            args.add(limit);
        }
        return ApiResponse.ok(rows(sql.toString(), args.toArray()));
    }

    public ApiResponse<Map<String, Object>> todoDetail(long userId, long id) {
        refreshOverdue(userId);
        List<Map<String, Object>> list = rows(todoSelectSql() + " WHERE t.user_id=? AND t.id=?", userId, id);
        if (list.isEmpty()) {
            return ApiResponse.fail("任务不存在");
        }
        return ApiResponse.ok(list.get(0));
    }

    public ApiResponse<Map<String, Object>> saveTodo(Map<String, Object> body) {
        long userId = longValue(body, "userId");
        String title = text(body, "title");
        String courseName = text(body, "courseName");
        if (userId <= 0 || title.isEmpty()) {
            return ApiResponse.fail("任务标题不能为空");
        }
        Long courseId = ensureCourse(userId, courseName, "", "");
        Timestamp deadline = parseTime(text(body, "deadline"));
        Long id = insert("INSERT INTO todo_task(user_id, course_id, title, description, task_type, platform, deadline, priority, status, source_type, source_record_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                userId,
                courseId,
                title,
                text(body, "description"),
                defaultText(body, "taskType", "其他"),
                defaultText(body, "platform", "其他"),
                deadline,
                defaultText(body, "priority", "中"),
                defaultText(body, "status", "待完成"),
                defaultText(body, "sourceType", "手动创建"),
                nullableLong(body, "sourceRecordId"));
        return todoDetail(userId, id);
    }

    public ApiResponse<Map<String, Object>> updateTodo(long id, Map<String, Object> body) {
        long userId = longValue(body, "userId");
        String title = text(body, "title");
        if (userId <= 0 || title.isEmpty()) {
            return ApiResponse.fail("任务标题不能为空");
        }
        Long courseId = ensureCourse(userId, text(body, "courseName"), "", "");
        jdbc.update("UPDATE todo_task SET course_id=?, title=?, description=?, task_type=?, platform=?, deadline=?, priority=?, status=? WHERE id=? AND user_id=?",
                courseId,
                title,
                text(body, "description"),
                defaultText(body, "taskType", "其他"),
                defaultText(body, "platform", "其他"),
                parseTime(text(body, "deadline")),
                defaultText(body, "priority", "中"),
                defaultText(body, "status", "待完成"),
                id,
                userId);
        return todoDetail(userId, id);
    }

    public ApiResponse<Boolean> deleteTodo(long userId, long id) {
        int updated = jdbc.update("DELETE FROM todo_task WHERE user_id=? AND id=?", userId, id);
        return ApiResponse.ok(updated > 0);
    }

    public ApiResponse<Boolean> clearUserData(long userId) {
        if (userId <= 0) {
            return ApiResponse.fail("用户不存在");
        }
        jdbc.update("DELETE FROM todo_task WHERE user_id=?", userId);
        jdbc.update("DELETE FROM ai_parse_record WHERE user_id=?", userId);
        jdbc.update("DELETE FROM ocr_record WHERE user_id=?", userId);
        jdbc.update("DELETE FROM course WHERE user_id=?", userId);
        return ApiResponse.ok(true);
    }

    public ApiResponse<Map<String, Object>> updateTodoStatus(long id, Map<String, Object> body) {
        long userId = longValue(body, "userId");
        String status = defaultText(body, "status", "待完成");
        jdbc.update("UPDATE todo_task SET status=? WHERE id=? AND user_id=?", status, id, userId);
        return todoDetail(userId, id);
    }

    public ApiResponse<Map<String, Object>> createOcrRecord(Map<String, Object> body) {
        long userId = longValue(body, "userId");
        String text = text(body, "ocrText");
        if (userId <= 0 || text.isEmpty()) {
            return ApiResponse.fail("OCR 文本不能为空");
        }
        Long id = insert("INSERT INTO ocr_record(user_id, image_path, ocr_text, recognize_status) VALUES (?, ?, ?, ?)",
                userId,
                text(body, "imagePath"),
                text,
                defaultText(body, "recognizeStatus", "成功"));
        return ocrDetail(userId, id);
    }

    public ApiResponse<List<Map<String, Object>>> ocrHistory(long userId) {
        return ApiResponse.ok(rows("SELECT o.id, o.user_id userId, o.image_path imagePath, o.ocr_text ocrText, LEFT(o.ocr_text, 80) ocrSummary, o.recognize_status recognizeStatus, o.ai_status aiStatus, o.generated_todo_id generatedTodoId, o.generated_task_title generatedTaskTitle, DATE_FORMAT(o.created_at, '%Y-%m-%d %H:%i') createdAt, DATE_FORMAT(o.updated_at, '%Y-%m-%d %H:%i') updatedAt FROM ocr_record o WHERE o.user_id=? ORDER BY o.created_at DESC", userId));
    }

    public ApiResponse<Map<String, Object>> ocrDetail(long userId, long id) {
        List<Map<String, Object>> list = rows("SELECT o.id, o.user_id userId, o.image_path imagePath, o.ocr_text ocrText, LEFT(o.ocr_text, 80) ocrSummary, o.recognize_status recognizeStatus, o.ai_status aiStatus, o.generated_todo_id generatedTodoId, o.generated_task_title generatedTaskTitle, DATE_FORMAT(o.created_at, '%Y-%m-%d %H:%i') createdAt, DATE_FORMAT(o.updated_at, '%Y-%m-%d %H:%i') updatedAt FROM ocr_record o WHERE o.user_id=? AND o.id=?", userId, id);
        if (list.isEmpty()) {
            return ApiResponse.fail("识别记录不存在");
        }
        Map<String, Object> data = list.get(0);
        data.put("aiRecords", rows("SELECT id, user_id userId, ocr_record_id ocrRecordId, raw_ai_response rawAiResponse, parsed_title title, parsed_course courseName, DATE_FORMAT(parsed_deadline, '%Y-%m-%d %H:%i') deadline, parsed_task_type taskType, parsed_platform platform, parsed_priority priority, parsed_description description, parse_status parseStatus, todo_generated todoGenerated, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') createdAt FROM ai_parse_record WHERE user_id=? AND ocr_record_id=? ORDER BY created_at DESC", userId, id));
        return ApiResponse.ok(data);
    }

    public ApiResponse<List<Map<String, Object>>> parseOcr(Map<String, Object> body) {
        long userId = longValue(body, "userId");
        long ocrRecordId = longValue(body, "ocrRecordId");
        String ocrText = text(body, "ocrText");
        String requestApiKey = firstNonBlank(text(body, "apiKey"), deepSeekApiKey);
        boolean shouldCallDeepSeek = requestApiKey != null && !requestApiKey.isBlank();
        if (userId <= 0 || ocrText.isEmpty()) {
            return ApiResponse.fail("OCR 文本不能为空");
        }
        List<ParsedTask> parsedTasks;
        List<ParsedTask> fallbackTasks = parseLocally(ocrText);
        String raw;
        String notice;
        if (!shouldCallDeepSeek) {
            parsedTasks = fallbackTasks;
            raw = "未调用 DeepSeek：API Key 未填写，已使用本地规则解析。";
            notice = raw;
        } else {
            try {
                DeepSeekParseResult aiResult = parseWithDeepSeek(ocrText, requestApiKey);
                parsedTasks = completeWithFallback(aiResult.parsedTasks, fallbackTasks);
                raw = aiResult.rawResponse;
                notice = "已调用 DeepSeek 模型 deepseek-chat，共识别 " + parsedTasks.size() + " 个任务，请逐个确认。";
            } catch (Exception ex) {
                return ApiResponse.fail("DeepSeek 调用失败，未使用本地规则兜底。请检查 API Key、余额、网络或官网用量记录。错误：" + ex.getMessage());
            }
        }
        if (parsedTasks.isEmpty()) {
            parsedTasks = fallbackTasks;
        }

        List<Map<String, Object>> records = new ArrayList<>();
        for (int i = 0; i < parsedTasks.size(); i++) {
            ParsedTask parsed = parsedTasks.get(i);
            Long id = insertAiParseRecord(userId, ocrRecordId, raw, parsed);
            Map<String, Object> data = aiDetail(userId, id);
            data.put("parserNotice", notice);
            data.put("parserCount", parsedTasks.size());
            data.put("parserIndex", i + 1);
            records.add(data);
        }
        if (ocrRecordId > 0) {
            jdbc.update("UPDATE ocr_record SET ai_status='已解析' WHERE id=? AND user_id=?", ocrRecordId, userId);
        }
        return ApiResponse.ok(records);
    }

    public ApiResponse<Map<String, Object>> confirmParsedTodo(Map<String, Object> body) {
        long userId = longValue(body, "userId");
        long aiParseRecordId = longValue(body, "aiParseRecordId");
        body.put("sourceType", "截图识别生成");
        if (body.get("sourceRecordId") == null && longValue(body, "ocrRecordId") > 0) {
            body.put("sourceRecordId", longValue(body, "ocrRecordId"));
        }
        ApiResponse<Map<String, Object>> todo = saveTodo(body);
        if (todo.getCode() == 200) {
            Map<String, Object> saved = todo.getData();
            long todoId = longValue(saved, "id");
            long ocrRecordId = longValue(body, "ocrRecordId");
            if (aiParseRecordId > 0) {
                jdbc.update("UPDATE ai_parse_record SET todo_generated=1 WHERE id=? AND user_id=?", aiParseRecordId, userId);
            }
            if (ocrRecordId > 0) {
                jdbc.update("UPDATE ocr_record SET generated_todo_id=?, generated_task_title=? WHERE id=? AND user_id=?", todoId, String.valueOf(saved.get("title")), ocrRecordId, userId);
            }
        }
        return todo;
    }

    public ApiResponse<Map<String, Object>> me(long userId) {
        Map<String, Object> user = findUserById(userId);
        if (user.isEmpty()) {
            return ApiResponse.fail("用户不存在");
        }
        user.put("totalTasks", count("SELECT COUNT(*) FROM todo_task WHERE user_id=?", userId));
        user.put("doneTasks", count("SELECT COUNT(*) FROM todo_task WHERE user_id=? AND status='已完成'", userId));
        user.put("ocrCount", count("SELECT COUNT(*) FROM ocr_record WHERE user_id=?", userId));
        user.put("deepSeekConfigured", deepSeekApiKey != null && !deepSeekApiKey.isEmpty());
        return ApiResponse.ok(user);
    }

    private Map<String, Object> aiDetail(long userId, long id) {
        List<Map<String, Object>> list = rows("SELECT id, user_id userId, ocr_record_id ocrRecordId, raw_ai_response rawAiResponse, parsed_title title, parsed_course courseName, DATE_FORMAT(parsed_deadline, '%Y-%m-%d %H:%i') deadline, parsed_task_type taskType, parsed_platform platform, parsed_priority priority, parsed_description description, parse_status parseStatus, todo_generated todoGenerated, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') createdAt FROM ai_parse_record WHERE user_id=? AND id=?", userId, id);
        return list.isEmpty() ? new LinkedHashMap<>() : list.get(0);
    }

    private Long insertAiParseRecord(long userId, long ocrRecordId, String raw, ParsedTask parsed) {
        return insert("INSERT INTO ai_parse_record(user_id, ocr_record_id, raw_ai_response, parsed_title, parsed_course, parsed_deadline, parsed_task_type, parsed_platform, parsed_priority, parsed_description, parse_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                userId,
                ocrRecordId > 0 ? ocrRecordId : null,
                raw,
                parsed.title,
                parsed.courseName,
                parseTime(parsed.deadline),
                parsed.taskType,
                parsed.platform,
                parsed.priority,
                parsed.description,
                "成功");
    }

    private String todoSelectSql() {
        return "SELECT t.id, t.user_id userId, t.course_id courseId, IFNULL(c.course_name, '') courseName, t.title, t.description, t.task_type taskType, t.platform, DATE_FORMAT(t.deadline, '%Y-%m-%d %H:%i') deadline, t.priority, t.status, t.source_type sourceType, t.source_record_id sourceRecordId, DATE_FORMAT(t.created_at, '%Y-%m-%d %H:%i') createdAt, DATE_FORMAT(t.updated_at, '%Y-%m-%d %H:%i') updatedAt FROM todo_task t LEFT JOIN course c ON t.course_id=c.id";
    }

    private String orderBy(String sortMode) {
        if ("优先级".equals(sortMode)) {
            return " ORDER BY CASE t.priority WHEN '高' THEN 0 WHEN '中' THEN 1 WHEN '低' THEN 2 ELSE 3 END, CASE WHEN t.deadline IS NULL THEN 1 ELSE 0 END, t.deadline ASC";
        }
        if ("开始时间".equals(sortMode)) {
            return " ORDER BY t.created_at ASC, CASE WHEN t.deadline IS NULL THEN 1 ELSE 0 END, t.deadline ASC";
        }
        if ("创建时间".equals(sortMode)) {
            return " ORDER BY t.created_at DESC, t.id DESC";
        }
        return " ORDER BY CASE WHEN t.deadline IS NULL THEN 1 ELSE 0 END, t.deadline ASC, t.created_at DESC";
    }

    private void refreshOverdue(long userId) {
        jdbc.update("UPDATE todo_task SET status='已逾期' WHERE user_id=? AND deadline IS NOT NULL AND deadline < NOW() AND status NOT IN ('已完成')", userId);
    }

    private Long ensureCourse(long userId, String courseName, String teacherName, String remark) {
        if (courseName == null || courseName.trim().isEmpty()) {
            return null;
        }
        List<Map<String, Object>> existing = rows("SELECT id FROM course WHERE user_id=? AND course_name=?", userId, courseName.trim());
        if (!existing.isEmpty()) {
            return longValue(existing.get(0), "id");
        }
        return insert("INSERT INTO course(user_id, course_name, teacher_name, remark) VALUES (?, ?, ?, ?)", userId, courseName.trim(), teacherName == null ? "" : teacherName, remark == null ? "" : remark);
    }

    private Map<String, Object> courseById(long id, long userId) {
        List<Map<String, Object>> list = rows("SELECT id, user_id userId, course_name courseName, teacher_name teacherName, color, remark, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') createdAt FROM course WHERE id=? AND user_id=?", id, userId);
        return list.isEmpty() ? new LinkedHashMap<>() : list.get(0);
    }

    private Map<String, Object> findUserById(long id) {
        List<Map<String, Object>> users = rows("SELECT id, username, DATE_FORMAT(created_at, '%Y-%m-%d %H:%i') createdAt, DATE_FORMAT(updated_at, '%Y-%m-%d %H:%i') updatedAt FROM snap_user WHERE id=?", id);
        return users.isEmpty() ? new LinkedHashMap<>() : users.get(0);
    }

    private List<ParsedTask> parseLocally(String text) {
        String normalized = text.replace("\r", "\n").trim();
        List<String> segments = splitTaskSegments(normalized);
        List<ParsedTask> tasks = new ArrayList<>();
        for (String segment : segments) {
            tasks.add(parseLocalSegment(segment, normalized));
        }
        if (tasks.isEmpty()) {
            tasks.add(parseLocalSegment(normalized, normalized));
        }
        return tasks;
    }

    private ParsedTask parseLocalSegment(String segment, String fullText) {
        ParsedTask task = new ParsedTask();
        String normalized = segment.replace("\r", "\n").trim();
        String context = normalized + "\n" + fullText;
        task.courseName = inferCourse(normalized);
        if ("未命名课程".equals(task.courseName)) {
            task.courseName = inferCourse(context);
        }
        task.taskType = inferTaskType(normalized);
        task.platform = inferPlatform(context);
        task.deadline = inferDeadline(normalized);
        task.priority = inferPriority(normalized, task.deadline);
        task.title = inferTitle(normalized, task.taskType);
        task.description = summarizeDescription(normalized, task);
        return task;
    }

    private List<String> splitTaskSegments(String text) {
        List<String> segments = new ArrayList<>();
        String[] lines = text.split("\n");
        for (String line : lines) {
            String clean = line.trim()
                    .replaceFirst("^[\\-•·*]+\\s*", "")
                    .replaceFirst("^\\d+[\\.、)]\\s*", "");
            if (clean.length() >= 4 && containsAny(clean, "作业", "实验", "报告", "测验", "考试", "讨论", "签到", "提交", "任务")) {
                segments.add(clean);
            }
        }
        if (segments.isEmpty()) {
            segments.add(text);
        }
        return segments;
    }

    private String summarizeDescription(String text, ParsedTask task) {
        List<String> parts = new ArrayList<>();
        if (task.title != null && !task.title.isBlank()) {
            parts.add("任务：" + task.title);
        }
        if (task.deadline != null && !task.deadline.isBlank()) {
            parts.add("截止时间：" + task.deadline);
        }
        if (task.platform != null && !task.platform.isBlank() && !"其他".equals(task.platform)) {
            parts.add("平台：" + task.platform);
        }
        String clean = text.replaceAll("\\s+", " ").trim();
        if (!clean.isEmpty() && (task.title == null || !clean.equals(task.title))) {
            parts.add("补充：" + (clean.length() > 120 ? clean.substring(0, 120) : clean));
        }
        return String.join("；", parts);
    }

    private DeepSeekParseResult parseWithDeepSeek(String ocrText, String apiKey) throws Exception {
        Map<String, Object> systemMessage = new LinkedHashMap<>();
        systemMessage.put("role", "system");
        systemMessage.put("content", "你是学生课程任务信息抽取助手。请只返回一个 JSON 对象，不要返回 Markdown。格式必须是 {\"tasks\":[...]}。每个 tasks 元素字段必须是 title, courseName, deadline, taskType, platform, priority, description。截图里有多个课程任务时必须拆成多个对象，不要合并。deadline 尽量使用 yyyy-MM-dd HH:mm；taskType 只能在 作业/实验/报告/测验/考试/讨论/签到/其他 中选择；platform 只能在 雨课堂/学习通/课堂派/微信群/QQ 群/线下提交/其他 中选择；priority 只能在 高/中/低 中选择。description 要写成适合 Todo 详情页的简洁说明，不要原样复制整段 OCR。没有依据的字段留空，不要编造。");

        Map<String, Object> userMessage = new LinkedHashMap<>();
        userMessage.put("role", "user");
        userMessage.put("content", "请从以下 OCR 文本中抽取所有可执行的课程任务。若有多个作业/实验/报告/测验/考试/签到等事项，请逐条放入 tasks 数组：\n" + ocrText);

        Map<String, Object> responseFormat = new LinkedHashMap<>();
        responseFormat.put("type", "json_object");

        Map<String, Object> requestBody = new LinkedHashMap<>();
        requestBody.put("model", "deepseek-chat");
        requestBody.put("messages", List.of(systemMessage, userMessage));
        requestBody.put("temperature", 0.1);
        requestBody.put("response_format", responseFormat);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(deepSeekApiUrl))
                .timeout(Duration.ofSeconds(45))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + apiKey.trim())
                .POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(requestBody)))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalStateException("HTTP " + response.statusCode() + " " + response.body());
        }

        JsonNode root = objectMapper.readTree(response.body());
        String content = root.path("choices").path(0).path("message").path("content").asText("");
        if (content.isBlank()) {
            throw new IllegalStateException("DeepSeek 返回内容为空");
        }
        JsonNode parsedRoot = objectMapper.readTree(extractJsonObject(content));
        List<ParsedTask> parsedTasks = tasksFromJson(parsedRoot);
        if (parsedTasks.isEmpty()) {
            throw new IllegalStateException("DeepSeek 返回了 JSON，但没有 tasks 任务数组");
        }

        DeepSeekParseResult result = new DeepSeekParseResult();
        result.parsedTasks = parsedTasks;
        result.rawResponse = response.body();
        return result;
    }

    private List<ParsedTask> tasksFromJson(JsonNode root) {
        List<ParsedTask> tasks = new ArrayList<>();
        JsonNode tasksNode = root.path("tasks");
        if (tasksNode.isArray()) {
            for (JsonNode node : tasksNode) {
                if (node.isObject()) {
                    tasks.add(parsedTaskFromJson(node));
                }
            }
        }
        if (tasks.isEmpty() && root.isObject() && root.has("title")) {
            tasks.add(parsedTaskFromJson(root));
        }
        return tasks;
    }

    private ParsedTask parsedTaskFromJson(JsonNode taskNode) {
        ParsedTask parsed = new ParsedTask();
        parsed.title = taskNode.path("title").asText("").trim();
        parsed.courseName = taskNode.path("courseName").asText("").trim();
        parsed.deadline = normalizeDeadline(taskNode.path("deadline").asText(""));
        parsed.taskType = normalizeChoice(taskNode.path("taskType").asText(""), "其他", "作业", "实验", "报告", "测验", "考试", "讨论", "签到", "其他");
        parsed.platform = normalizeChoice(taskNode.path("platform").asText(""), "其他", "雨课堂", "学习通", "课堂派", "微信群", "QQ 群", "线下提交", "其他");
        parsed.priority = normalizeChoice(taskNode.path("priority").asText(""), "中", "高", "中", "低");
        parsed.description = taskNode.path("description").asText("").trim();
        return parsed;
    }

    private List<ParsedTask> completeWithFallback(List<ParsedTask> aiTasks, List<ParsedTask> fallbackTasks) {
        if (aiTasks == null || aiTasks.isEmpty()) {
            return fallbackTasks;
        }
        List<ParsedTask> mergedTasks = new ArrayList<>();
        for (int i = 0; i < aiTasks.size(); i++) {
            ParsedTask fallback = fallbackTasks.isEmpty() ? new ParsedTask() : fallbackTasks.get(Math.min(i, fallbackTasks.size() - 1));
            mergedTasks.add(completeTask(aiTasks.get(i), fallback));
        }
        return mergedTasks;
    }

    private ParsedTask completeTask(ParsedTask ai, ParsedTask fallback) {
        ParsedTask merged = new ParsedTask();
        merged.title = firstNonBlank(ai.title, fallback.title, "课程任务");
        merged.courseName = firstNonBlank(ai.courseName, fallback.courseName, "未命名课程");
        merged.deadline = firstNonBlank(ai.deadline, fallback.deadline, "");
        merged.taskType = firstNonBlank(ai.taskType, fallback.taskType, "其他");
        merged.platform = firstNonBlank(ai.platform, fallback.platform, "其他");
        merged.priority = firstNonBlank(ai.priority, fallback.priority, "中");
        merged.description = firstNonBlank(ai.description, fallback.description, "");
        return merged;
    }

    private String extractJsonObject(String content) {
        String clean = content.trim();
        if (clean.startsWith("```")) {
            clean = clean.replaceFirst("^```json", "").replaceFirst("^```", "").replaceFirst("```$", "").trim();
        }
        int start = clean.indexOf('{');
        int end = clean.lastIndexOf('}');
        if (start >= 0 && end > start) {
            return clean.substring(start, end + 1);
        }
        return clean;
    }

    private String normalizeDeadline(String value) {
        if (value == null || value.trim().isEmpty()) {
            return "";
        }
        Timestamp parsed = parseTime(value);
        if (parsed != null) {
            return format(parsed.toLocalDateTime());
        }
        return inferDeadline(value);
    }

    private String normalizeChoice(String value, String defaultValue, String... allowed) {
        if (value == null || value.trim().isEmpty()) {
            return defaultValue;
        }
        String clean = value.trim();
        for (String item : allowed) {
            if (item.equals(clean)) {
                return clean;
            }
        }
        for (String item : allowed) {
            if (clean.contains(item)) {
                return item;
            }
        }
        return defaultValue;
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.trim().isEmpty()) {
                return value.trim();
            }
        }
        return "";
    }

    private String inferTitle(String text, String taskType) {
        String[] lines = text.split("\n");
        for (String line : lines) {
            String clean = line.trim();
            if (clean.length() >= 4 && containsAny(clean, "作业", "实验", "报告", "测验", "考试", "讨论", "签到", "提交")) {
                return clean.length() > 60 ? clean.substring(0, 60) : clean;
            }
        }
        for (String line : lines) {
            String clean = line.trim();
            if (!clean.isEmpty()) {
                return (taskType == null ? "课程任务" : taskType) + "：" + (clean.length() > 30 ? clean.substring(0, 30) : clean);
            }
        }
        return "课程任务";
    }

    private String inferCourse(String text) {
        Matcher book = Pattern.compile("《([^》]{2,40})》").matcher(text);
        if (book.find()) {
            return book.group(1);
        }
        Matcher label = Pattern.compile("(课程|科目)[:：\\s]+([^\\n，,。；;\\s]{2,40})").matcher(text);
        if (label.find()) {
            return label.group(2).trim();
        }
        String[] known = {"移动应用开发", "计算机系统基础", "数据库", "并行程序设计", "软件工程", "高等数学", "大学英语"};
        for (String item : known) {
            if (text.contains(item)) {
                return item;
            }
        }
        return "未命名课程";
    }

    private String inferTaskType(String text) {
        if (containsAny(text, "实验")) return "实验";
        if (containsAny(text, "报告", "论文")) return "报告";
        if (containsAny(text, "测验", "小测")) return "测验";
        if (containsAny(text, "考试")) return "考试";
        if (containsAny(text, "讨论")) return "讨论";
        if (containsAny(text, "签到")) return "签到";
        if (containsAny(text, "作业", "习题")) return "作业";
        return "其他";
    }

    private String inferPlatform(String text) {
        if (text.contains("雨课堂")) return "雨课堂";
        if (text.contains("学习通") || text.contains("超星")) return "学习通";
        if (text.contains("课堂派")) return "课堂派";
        if (text.contains("微信群") || text.contains("微信")) return "微信群";
        if (text.contains("QQ群") || text.contains("QQ")) return "QQ 群";
        if (text.contains("线下")) return "线下提交";
        return "其他";
    }

    private String inferPriority(String text, String deadline) {
        if (containsAny(text, "考试", "测验", "今天", "今晚", "明天", "紧急")) {
            return "高";
        }
        if (deadline == null || deadline.isEmpty()) {
            return "中";
        }
        Timestamp deadlineTime = parseTime(deadline);
        if (deadlineTime != null && deadlineTime.toLocalDateTime().isBefore(LocalDateTime.now().plusDays(2))) {
            return "高";
        }
        return "中";
    }

    private String inferDeadline(String text) {
        Matcher full = Pattern.compile("(20\\d{2})[-年/\\.](\\d{1,2})[-月/\\.](\\d{1,2})[日号]?\\s*(\\d{1,2})?[:：点]?(\\d{1,2})?").matcher(text);
        if (full.find()) {
            int year = Integer.parseInt(full.group(1));
            int month = Integer.parseInt(full.group(2));
            int day = Integer.parseInt(full.group(3));
            int hour = full.group(4) == null ? 23 : Integer.parseInt(full.group(4));
            int minute = full.group(5) == null ? 59 : Integer.parseInt(full.group(5));
            return format(LocalDateTime.of(year, month, day, hour, minute));
        }
        Matcher md = Pattern.compile("(\\d{1,2})月(\\d{1,2})[日号]?\\s*(\\d{1,2})?[:：点]?(\\d{1,2})?").matcher(text);
        if (md.find()) {
            int year = LocalDate.now().getYear();
            int month = Integer.parseInt(md.group(1));
            int day = Integer.parseInt(md.group(2));
            int hour = md.group(3) == null ? 23 : Integer.parseInt(md.group(3));
            int minute = md.group(4) == null ? 59 : Integer.parseInt(md.group(4));
            return format(LocalDateTime.of(year, month, day, hour, minute));
        }
        if (text.contains("明天")) {
            return format(LocalDate.now().plusDays(1).atTime(23, 59));
        }
        if (text.contains("今天") || text.contains("今晚")) {
            return format(LocalDate.now().atTime(23, 59));
        }
        return "";
    }

    private boolean containsAny(String text, String... keywords) {
        for (String keyword : keywords) {
            if (text.contains(keyword)) {
                return true;
            }
        }
        return false;
    }

    private Timestamp parseTime(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        String clean = value.trim().replace("T", " ");
        List<DateTimeFormatter> formatters = new ArrayList<>();
        formatters.add(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        formatters.add(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
        formatters.add(DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm"));
        formatters.add(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        for (DateTimeFormatter formatter : formatters) {
            try {
                if (formatter.toString().contains("HourOfDay")) {
                    return Timestamp.valueOf(LocalDateTime.parse(clean, formatter));
                }
                return Timestamp.valueOf(LocalDate.parse(clean, formatter).atTime(23, 59));
            } catch (Exception ignored) {
            }
        }
        return null;
    }

    private String format(LocalDateTime time) {
        return time.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
    }

    private int count(String sql, Object... args) {
        Integer value = jdbc.queryForObject(sql, Integer.class, args);
        return value == null ? 0 : value;
    }

    private Long insert(String sql, Object... args) {
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            for (int i = 0; i < args.length; i++) {
                ps.setObject(i + 1, args[i]);
            }
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        return key == null ? 0L : key.longValue();
    }

    private List<Map<String, Object>> rows(String sql, Object... args) {
        return jdbc.query(sql, (rs, rowNum) -> {
            Map<String, Object> row = new LinkedHashMap<>();
            int count = rs.getMetaData().getColumnCount();
            for (int i = 1; i <= count; i++) {
                Object value = rs.getObject(i);
                if (value instanceof Timestamp) {
                    value = ((Timestamp) value).toLocalDateTime().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
                }
                row.put(rs.getMetaData().getColumnLabel(i), value);
            }
            return row;
        }, args);
    }

    private String text(Map<String, Object> body, String key) {
        Object value = body.get(key);
        return value == null ? "" : String.valueOf(value).trim();
    }

    private String defaultText(Map<String, Object> body, String key, String defaultValue) {
        String value = text(body, key);
        return value.isEmpty() ? defaultValue : value;
    }

    private long longValue(Map<String, Object> body, String key) {
        Object value = body.get(key);
        if (value == null) {
            return 0;
        }
        if (value instanceof Number) {
            return ((Number) value).longValue();
        }
        try {
            return Long.parseLong(String.valueOf(value));
        } catch (Exception ignored) {
            return 0;
        }
    }

    private Long nullableLong(Map<String, Object> body, String key) {
        long value = longValue(body, key);
        return value <= 0 ? null : value;
    }

    private static class ParsedTask {
        String title;
        String courseName;
        String deadline;
        String taskType;
        String platform;
        String priority;
        String description;
    }

    private static class DeepSeekParseResult {
        List<ParsedTask> parsedTasks;
        String rawResponse;
    }
}
