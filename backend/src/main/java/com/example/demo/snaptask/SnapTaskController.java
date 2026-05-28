package com.example.demo.snaptask;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class SnapTaskController {
    private final SnapTaskService service;

    public SnapTaskController(SnapTaskService service) {
        this.service = service;
    }

    @PostMapping("/auth/register")
    public ApiResponse<Map<String, Object>> register(@RequestBody Map<String, Object> body) {
        return service.register(body);
    }

    @PostMapping("/auth/login")
    public ApiResponse<Map<String, Object>> login(@RequestBody Map<String, Object> body) {
        return service.login(body);
    }

    @GetMapping("/dashboard")
    public ApiResponse<Map<String, Object>> dashboard(@RequestParam long userId,
                                                      @RequestParam(defaultValue = "截止时间") String sortMode) {
        return service.dashboard(userId, sortMode);
    }

    @GetMapping("/courses")
    public ApiResponse<List<Map<String, Object>>> courses(@RequestParam long userId) {
        return service.courses(userId);
    }

    @PostMapping("/courses")
    public ApiResponse<Map<String, Object>> saveCourse(@RequestBody Map<String, Object> body) {
        return service.saveCourse(body);
    }

    @GetMapping("/todos")
    public ApiResponse<List<Map<String, Object>>> todos(@RequestParam long userId,
                                                        @RequestParam(defaultValue = "全部") String status,
                                                        @RequestParam(defaultValue = "0") long courseId,
                                                        @RequestParam(defaultValue = "全部") String priority,
                                                        @RequestParam(defaultValue = "0") int limit,
                                                        @RequestParam(defaultValue = "截止时间") String sortMode) {
        return service.todos(userId, status, courseId, priority, limit, sortMode);
    }

    @GetMapping("/todos/{id}")
    public ApiResponse<Map<String, Object>> todoDetail(@PathVariable long id, @RequestParam long userId) {
        return service.todoDetail(userId, id);
    }

    @PostMapping("/todos")
    public ApiResponse<Map<String, Object>> saveTodo(@RequestBody Map<String, Object> body) {
        return service.saveTodo(body);
    }

    @PutMapping("/todos/{id}")
    public ApiResponse<Map<String, Object>> updateTodo(@PathVariable long id, @RequestBody Map<String, Object> body) {
        return service.updateTodo(id, body);
    }

    @PatchMapping("/todos/{id}/status")
    public ApiResponse<Map<String, Object>> updateTodoStatus(@PathVariable long id, @RequestBody Map<String, Object> body) {
        return service.updateTodoStatus(id, body);
    }

    @PostMapping("/todos/{id}/status")
    public ApiResponse<Map<String, Object>> updateTodoStatusByPost(@PathVariable long id, @RequestBody Map<String, Object> body) {
        return service.updateTodoStatus(id, body);
    }

    @DeleteMapping("/todos/{id}")
    public ApiResponse<Boolean> deleteTodo(@PathVariable long id, @RequestParam long userId) {
        return service.deleteTodo(userId, id);
    }

    @PostMapping("/todos/{id}/delete")
    public ApiResponse<Boolean> deleteTodoByPost(@PathVariable long id,
                                                 @RequestParam(required = false) Long userId,
                                                 @RequestBody(required = false) Map<String, Object> body) {
        long resolvedUserId = userId == null ? longValue(body, "userId") : userId;
        return service.deleteTodo(resolvedUserId, id);
    }

    @DeleteMapping("/users/{userId}/data")
    public ApiResponse<Boolean> clearUserData(@PathVariable long userId) {
        return service.clearUserData(userId);
    }

    @PostMapping("/users/{userId}/data/clear")
    public ApiResponse<Boolean> clearUserDataByPost(@PathVariable long userId) {
        return service.clearUserData(userId);
    }

    private long longValue(Map<String, Object> body, String key) {
        if (body == null) {
            return 0;
        }
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

    @PostMapping("/ocr/records")
    public ApiResponse<Map<String, Object>> createOcrRecord(@RequestBody Map<String, Object> body) {
        return service.createOcrRecord(body);
    }

    @GetMapping("/ocr/records")
    public ApiResponse<List<Map<String, Object>>> ocrHistory(@RequestParam long userId) {
        return service.ocrHistory(userId);
    }

    @GetMapping("/ocr/records/{id}")
    public ApiResponse<Map<String, Object>> ocrDetail(@PathVariable long id, @RequestParam long userId) {
        return service.ocrDetail(userId, id);
    }

    @PostMapping("/ai/parse")
    public ApiResponse<List<Map<String, Object>>> parseOcr(@RequestBody Map<String, Object> body) {
        return service.parseOcr(body);
    }

    @PostMapping("/ai/confirm")
    public ApiResponse<Map<String, Object>> confirmParsedTodo(@RequestBody Map<String, Object> body) {
        return service.confirmParsedTodo(body);
    }

    @GetMapping("/me")
    public ApiResponse<Map<String, Object>> me(@RequestParam long userId) {
        return service.me(userId);
    }
}
