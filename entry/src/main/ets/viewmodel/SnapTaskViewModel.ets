import { OcrModel } from '../model/OcrModel';
import { SnapTaskRepository } from '../model/SnapTaskRepository';
import { AiParseRecord, DashboardData, OcrRecord, TodoDraft, TodoTask, UserSession } from '../model/Models';

@ObservedV2
export class SnapTaskViewModel {
  private readonly repository: SnapTaskRepository = new SnapTaskRepository();
  private readonly ocrModel: OcrModel = new OcrModel();

  @Trace screen: string = 'auth';
  @Trace authMode: string = 'login';
  @Trace loading: boolean = false;
  @Trace notice: string = 'SnapTask 已连接后端 10.128.18.93:8080';

  @Trace user: UserSession = new UserSession();
  @Trace loginUsername: string = '';
  @Trace loginPassword: string = '';
  @Trace registerUsername: string = '';
  @Trace registerPassword: string = '';
  @Trace registerConfirm: string = '';

  @Trace dashboard: DashboardData = new DashboardData();
  @Trace todos: TodoTask[] = [];
  @Trace completedTodos: TodoTask[] = [];
  @Trace histories: OcrRecord[] = [];
  @Trace currentTodo: TodoTask = new TodoTask();
  @Trace selectedCompletedTodo: TodoTask = new TodoTask();
  @Trace currentHistory: OcrRecord = new OcrRecord();
  @Trace selectedHistoryId: number = 0;
  @Trace selectedCompletedTodoId: number = 0;
  @Trace selectedCompletedDetailVersion: number = 0;
  @Trace filterStatus: string = '全部';
  @Trace sortMode: string = '截止时间';
  @Trace showSortSettings: boolean = false;
  @Trace detailBackScreen: string = 'home';

  @Trace selectedImage: string = '尚未选择截图';
  @Trace selectedImageUri: string = '';
  @Trace ocrText: string = '';
  @Trace recognizing: boolean = false;
  @Trace ocrRecord: OcrRecord = new OcrRecord();
  @Trace aiParsed: AiParseRecord = new AiParseRecord();
  @Trace aiParsedList: AiParseRecord[] = [];
  @Trace aiParsedIndex: number = 0;
  @Trace parsedDrafts: TodoDraft[] = [];
  @Trace confirmFormVersion: number = 0;
  @Trace draft: TodoDraft = new TodoDraft();
  @Trace deepSeekApiKey: string = '';
  @Trace clearConfirmArmed: boolean = false;
  private historyRequestSeq: number = 0;

  async loadWorkspace(): Promise<void> {
    if (this.user.id <= 0) {
      return;
    }
    await this.loadDashboard();
    await this.loadTodos();
  }

  async loadDashboard(): Promise<void> {
    let result = await this.repository.dashboard(this.user.id, this.sortMode);
    if (result.code === 200) {
      this.dashboard = result.data;
    } else {
      this.notice = result.message;
    }
  }

  async loadTodos(): Promise<void> {
    let result = await this.repository.todos(this.user.id, '全部', this.sortMode);
    if (result.code === 200) {
      this.splitTodos(result.data);
    } else {
      this.notice = result.message;
    }
  }

  splitTodos(source: TodoTask[]): void {
    let active: TodoTask[] = [];
    let completed: TodoTask[] = [];
    for (let i = 0; i < source.length; i++) {
      if (source[i].status === '已完成') {
        completed.push(source[i]);
      } else {
        active.push(source[i]);
      }
    }
    this.todos = active;
    this.completedTodos = completed;
    if (completed.length === 0) {
      this.selectedCompletedTodo = new TodoTask();
      this.selectedCompletedTodoId = 0;
      this.selectedCompletedDetailVersion += 1;
      return;
    }
    let matched = false;
    for (let i = 0; i < completed.length; i++) {
      if (completed[i].id === this.selectedCompletedTodoId) {
        this.selectedCompletedTodo = this.cloneTodo(completed[i]);
        matched = true;
        break;
      }
    }
    if (!matched) {
      this.selectedCompletedTodo = this.cloneTodo(completed[0]);
      this.selectedCompletedTodoId = completed[0].id;
      this.selectedCompletedDetailVersion += 1;
    }
  }

  cloneTodo(source: TodoTask): TodoTask {
    let next = new TodoTask();
    next.id = source.id;
    next.userId = source.userId;
    next.courseId = source.courseId;
    next.courseName = source.courseName;
    next.title = source.title;
    next.description = source.description;
    next.taskType = source.taskType;
    next.platform = this.normalizePlatform(source.platform);
    next.deadline = source.deadline;
    next.priority = source.priority;
    next.status = source.status;
    next.sourceType = source.sourceType;
    next.sourceRecordId = source.sourceRecordId;
    next.createdAt = source.createdAt;
    next.updatedAt = source.updatedAt;
    return next;
  }

  async loadHistory(): Promise<void> {
    let result = await this.repository.history(this.user.id);
    if (result.code === 200) {
      this.histories = result.data;
    }
  }

  async doLogin(): Promise<void> {
    this.loading = true;
    let result = await this.repository.login(this.loginUsername.trim(), this.loginPassword);
    if (result.code === 200) {
      this.user = result.data;
      this.screen = 'home';
      this.notice = `欢迎回来，${this.user.username}`;
      await this.loadWorkspace();
    } else {
      this.notice = result.message;
    }
    this.loading = false;
  }

  async doRegister(): Promise<void> {
    this.loading = true;
    let result = await this.repository.register(this.registerUsername.trim(), this.registerPassword, this.registerConfirm);
    if (result.code === 200) {
      this.authMode = 'login';
      this.loginUsername = this.registerUsername;
      this.loginPassword = this.registerPassword;
      this.notice = '注册成功，请登录';
    } else {
      this.notice = result.message;
    }
    this.loading = false;
  }

  async pickDeviceImage(): Promise<void> {
    try {
      let picked = await this.ocrModel.pickImage();
      if (picked.imageUri.length === 0) {
        this.notice = '没有选择图片';
        return;
      }
      this.selectedImage = picked.imageName;
      this.selectedImageUri = picked.imageUri;
      this.ocrText = '';
      this.notice = '图片已选择，可以开始本地 OCR 识别';
    } catch (error) {
      this.notice = `选择图片失败：${this.ocrModel.errorText(error as Object)}`;
    }
  }

  async runOcr(): Promise<void> {
    if (this.selectedImageUri.length === 0) {
      this.notice = '请先选择一张截图；如果暂时没有图片，也可以直接在 OCR 原文框里手动粘贴文字';
      return;
    }

    this.recognizing = true;
    this.notice = '正在调用鸿蒙端侧 OCR 识别图片文字';
    try {
      let text = await this.ocrModel.recognizeImage(this.selectedImageUri);
      if (text.trim().length === 0) {
        this.notice = 'OCR 没有识别到文字，可以换一张更清晰的截图或手动粘贴文本';
      } else {
        this.ocrText = text;
        this.notice = '本地 OCR 识别完成，请检查文字后继续 AI 解析';
      }
    } catch (error) {
      this.notice = `OCR 识别失败：${this.ocrModel.errorText(error as Object)}。可以先手动粘贴文本继续解析`;
    }
    this.recognizing = false;
  }

  async parseOcr(): Promise<void> {
    if (this.ocrText.trim().length === 0) {
      this.notice = 'OCR 文本为空，不能继续 AI 解析';
      return;
    }
    this.loading = true;
    this.notice = this.deepSeekApiKey.trim().length > 0
      ? '正在调用 DeepSeek 模型 deepseek-chat 解析 OCR 文本'
      : '未填写 DeepSeek API Key，将使用本地规则解析';
    let ocr = await this.repository.createOcrRecord(this.user.id, this.selectedImage, this.ocrText);
    if (ocr.code !== 200) {
      this.notice = ocr.message;
      this.loading = false;
      return;
    }
    this.ocrRecord = ocr.data;
    let parsed = await this.repository.parseOcr(this.user.id, this.ocrRecord.id, this.ocrText, this.deepSeekApiKey.trim());
    if (parsed.code === 200 && parsed.data.length > 0) {
      this.aiParsedList = parsed.data;
      this.parsedDrafts = this.buildDrafts(parsed.data);
      this.aiParsedIndex = 0;
      this.aiParsed = this.aiParsedList[0];
      this.draft = this.cloneDraft(this.parsedDrafts[0]);
      this.confirmFormVersion += 1;
      this.screen = 'confirm';
      let notice = this.aiParsed.parserNotice.length > 0 ? this.aiParsed.parserNotice : 'AI 解析完成，请确认任务';
      this.notice = `${notice} 当前第 1/${this.aiParsedList.length} 个`;
    } else if (parsed.code === 200) {
      this.notice = 'AI 没有解析出可生成的任务，可以修改 OCR 文本后重试';
    } else {
      this.notice = parsed.message;
    }
    this.loading = false;
  }

  buildDrafts(records: AiParseRecord[]): TodoDraft[] {
    let drafts: TodoDraft[] = [];
    for (let i = 0; i < records.length; i++) {
      drafts.push(this.buildDraftFromParsed(records[i]));
    }
    return drafts;
  }

  buildDraftFromParsed(record: AiParseRecord): TodoDraft {
    let next = new TodoDraft();
    next.userId = this.user.id;
    next.aiParseRecordId = record.id;
    next.ocrRecordId = this.ocrRecord.id;
    next.sourceRecordId = this.ocrRecord.id;
    next.title = record.title;
    next.courseName = record.courseName;
    next.taskType = record.taskType;
    next.platform = this.normalizePlatform(record.platform);
    next.deadline = record.deadline;
    next.priority = record.priority;
    next.description = record.description;
    next.sourceType = '截图识别生成';
    return next;
  }

  cloneDraft(source: TodoDraft): TodoDraft {
    let next = new TodoDraft();
    next.userId = source.userId;
    next.aiParseRecordId = source.aiParseRecordId;
    next.ocrRecordId = source.ocrRecordId;
    next.sourceRecordId = source.sourceRecordId;
    next.title = source.title;
    next.courseName = source.courseName;
    next.taskType = source.taskType;
    next.platform = this.normalizePlatform(source.platform);
    next.deadline = source.deadline;
    next.priority = source.priority;
    next.status = source.status;
    next.description = source.description;
    next.sourceType = source.sourceType;
    return next;
  }

  normalizePlatform(value: string): string {
    if (value === '学习通') {
      return '小雅';
    }
    if (value === '课堂派') {
      return '飞书';
    }
    return value;
  }

  cloneHistory(source: OcrRecord): OcrRecord {
    let next = new OcrRecord();
    next.id = source.id;
    next.userId = source.userId;
    next.imagePath = source.imagePath;
    next.ocrText = source.ocrText;
    next.ocrSummary = source.ocrSummary;
    next.recognizeStatus = source.recognizeStatus;
    next.aiStatus = source.aiStatus;
    next.generatedTodoId = source.generatedTodoId;
    next.generatedTaskTitle = source.generatedTaskTitle;
    next.createdAt = source.createdAt;
    next.updatedAt = source.updatedAt;
    next.aiRecords = source.aiRecords;
    return next;
  }

  copyParsedToDraft(): void {
    this.draft = this.buildDraftFromParsed(this.aiParsed);
    this.saveCurrentParsedDraft();
  }

  saveCurrentParsedDraft(): void {
    if (this.aiParsedIndex < 0 || this.aiParsedIndex >= this.parsedDrafts.length) {
      return;
    }
    let drafts: TodoDraft[] = [];
    for (let i = 0; i < this.parsedDrafts.length; i++) {
      drafts.push(i === this.aiParsedIndex ? this.cloneDraft(this.draft) : this.cloneDraft(this.parsedDrafts[i]));
    }
    this.parsedDrafts = drafts;
  }

  selectParsed(index: number): void {
    if (index < 0 || index >= this.aiParsedList.length) {
      return;
    }
    this.saveCurrentParsedDraft();
    this.aiParsedIndex = index;
    this.aiParsed = this.aiParsedList[index];
    this.draft = this.cloneDraft(this.parsedDrafts[index]);
    this.confirmFormVersion += 1;
    this.notice = `正在确认第 ${index + 1}/${this.aiParsedList.length} 个任务`;
  }

  previousParsed(): void {
    this.selectParsed(this.aiParsedIndex - 1);
  }

  nextParsed(): void {
    this.selectParsed(this.aiParsedIndex + 1);
  }

  markParsedGenerated(aiParseRecordId: number): void {
    let records: AiParseRecord[] = [];
    for (let i = 0; i < this.aiParsedList.length; i++) {
      let record = this.aiParsedList[i];
      if (record.id === aiParseRecordId) {
        record.todoGenerated = 1;
      }
      records.push(record);
    }
    this.aiParsedList = records;
    if (this.aiParsed.id === aiParseRecordId) {
      this.aiParsed.todoGenerated = 1;
    }
  }

  nextPendingParsedIndex(): number {
    for (let i = 0; i < this.aiParsedList.length; i++) {
      if (this.aiParsedList[i].todoGenerated !== 1) {
        return i;
      }
    }
    return -1;
  }

  newManualTodo(): void {
    let next = new TodoDraft();
    next.userId = this.user.id;
    next.title = '';
    next.courseName = '';
    next.deadline = '';
    next.description = '';
    next.sourceType = '手动创建';
    this.draft = next;
    this.aiParsed = new AiParseRecord();
    this.aiParsedList = [];
    this.aiParsedIndex = 0;
    this.parsedDrafts = [];
    this.confirmFormVersion += 1;
    this.ocrRecord = new OcrRecord();
    this.screen = 'manual';
    this.notice = '正在手动创建任务';
  }

  setDraftField(field: string, value: string): void {
    let next = new TodoDraft();
    next.userId = this.draft.userId;
    next.aiParseRecordId = this.draft.aiParseRecordId;
    next.ocrRecordId = this.draft.ocrRecordId;
    next.sourceRecordId = this.draft.sourceRecordId;
    next.title = this.draft.title;
    next.courseName = this.draft.courseName;
    next.taskType = this.draft.taskType;
    next.platform = this.draft.platform;
    next.deadline = this.draft.deadline;
    next.priority = this.draft.priority;
    next.status = this.draft.status;
    next.description = this.draft.description;
    next.sourceType = this.draft.sourceType;
    if (field === 'title') {
      next.title = value;
    } else if (field === 'courseName') {
      next.courseName = value;
    } else if (field === 'taskType') {
      next.taskType = value;
    } else if (field === 'platform') {
      next.platform = this.normalizePlatform(value);
    } else if (field === 'deadline') {
      next.deadline = value;
    } else if (field === 'priority') {
      next.priority = value;
    } else if (field === 'description') {
      next.description = value;
    }
    this.draft = next;
    if (this.aiParsedList.length > 0) {
      this.saveCurrentParsedDraft();
    }
    if (field === 'taskType' || field === 'platform' || field === 'priority') {
      this.confirmFormVersion += 1;
      this.notice = `${this.labelForField(field)}已切换为：${value}`;
    }
  }

  labelForField(field: string): string {
    if (field === 'taskType') {
      return '任务类型';
    }
    if (field === 'platform') {
      return '提交平台';
    }
    if (field === 'priority') {
      return '优先级';
    }
    return '字段';
  }

  async saveDraft(): Promise<void> {
    if (this.draft.title.trim().length === 0) {
      this.notice = '任务标题不能为空';
      return;
    }
    this.loading = true;
    this.draft.userId = this.user.id;
    this.saveCurrentParsedDraft();
    let result = this.draft.aiParseRecordId > 0
      ? await this.repository.confirmParsedTodo(this.draft)
      : await this.repository.createTodo(this.draft);
    if (result.code === 200) {
      this.currentTodo = result.data;
      await this.loadWorkspace();
      if (this.draft.aiParseRecordId > 0) {
        this.markParsedGenerated(this.draft.aiParseRecordId);
        let nextIndex = this.nextPendingParsedIndex();
        if (nextIndex >= 0 && this.aiParsedList.length > 1) {
          this.selectParsed(nextIndex);
          this.notice = `已保存 1 个 Todo，继续确认第 ${nextIndex + 1}/${this.aiParsedList.length} 个任务`;
          this.loading = false;
          return;
        }
      }
      this.detailBackScreen = this.draft.aiParseRecordId > 0 ? 'home' : 'manual';
      this.screen = 'detail';
      this.notice = 'Todo 已保存到数据库';
    } else {
      this.notice = result.message;
    }
    this.loading = false;
  }

  async saveAllParsedDrafts(): Promise<void> {
    if (this.aiParsedList.length === 0) {
      await this.saveDraft();
      return;
    }
    this.saveCurrentParsedDraft();
    this.loading = true;
    let savedCount = 0;
    let lastTodo = new TodoTask();
    for (let i = 0; i < this.aiParsedList.length; i++) {
      if (this.aiParsedList[i].todoGenerated === 1) {
        continue;
      }
      let draft = this.cloneDraft(this.parsedDrafts[i]);
      draft.userId = this.user.id;
      if (draft.title.trim().length === 0) {
        this.loading = false;
        this.selectParsed(i);
        this.notice = `第 ${i + 1} 个任务标题为空，请补全后再保存`;
        return;
      }
      let result = await this.repository.confirmParsedTodo(draft);
      if (result.code !== 200) {
        this.loading = false;
        this.selectParsed(i);
        this.notice = result.message;
        return;
      }
      savedCount += 1;
      lastTodo = result.data;
      this.markParsedGenerated(draft.aiParseRecordId);
    }
    await this.loadWorkspace();
    this.currentTodo = lastTodo;
    this.screen = 'home';
    this.notice = savedCount > 0 ? `已生成 ${savedCount} 个 Todo` : '这些任务已经生成过 Todo';
    this.loading = false;
  }

  async openTodo(item: TodoTask): Promise<void> {
    this.detailBackScreen = this.screen === 'detail' ? 'home' : this.screen;
    let result = await this.repository.todoDetail(this.user.id, item.id);
    if (result.code === 200) {
      this.currentTodo = result.data;
      this.screen = 'detail';
    } else {
      this.notice = result.message;
    }
  }

  async setTodoStatus(status: string): Promise<void> {
    let result = await this.repository.updateTodoStatus(this.user.id, this.currentTodo.id, status);
    if (result.code === 200) {
      this.currentTodo = result.data;
      await this.loadWorkspace();
      this.notice = `任务已标记为${status}`;
    } else {
      this.notice = result.message;
    }
  }

  async completeTodo(item: TodoTask): Promise<void> {
    let result = await this.repository.updateTodoStatus(this.user.id, item.id, '已完成');
    if (result.code === 200) {
      this.currentTodo = result.data;
      this.selectedCompletedTodo = this.cloneTodo(result.data);
      this.selectedCompletedTodoId = result.data.id;
      this.selectedCompletedDetailVersion += 1;
      await this.loadWorkspace();
      this.notice = '任务已完成，已存入历史';
    } else {
      this.notice = result.message;
    }
  }

  selectCompletedTodo(item: TodoTask): void {
    this.selectedCompletedTodo = this.cloneTodo(item);
    this.selectedCompletedTodoId = item.id;
    this.selectedCompletedDetailVersion += 1;
    this.notice = '已打开完成任务详情';
  }

  async removeCurrentTodo(): Promise<void> {
    let result = await this.repository.deleteTodo(this.user.id, this.currentTodo.id);
    if (result.code === 200) {
      await this.loadWorkspace();
      this.screen = 'home';
      this.notice = '任务已删除';
    } else {
      this.notice = result.message;
    }
  }

  async openHistory(item: OcrRecord): Promise<void> {
    let requestSeq = ++this.historyRequestSeq;
    this.selectedHistoryId = item.id;
    this.currentHistory = this.cloneHistory(item);
    let result = await this.repository.historyDetail(this.user.id, item.id);
    if (requestSeq !== this.historyRequestSeq) {
      return;
    }
    if (result.code === 200) {
      this.currentHistory = this.cloneHistory(result.data);
      this.notice = '已打开识别历史详情';
    } else {
      this.notice = result.message;
    }
  }

  async navigateTo(target: string): Promise<void> {
    if (target === 'manual') {
      this.newManualTodo();
      return;
    }
    if (target === 'todos') {
      this.screen = 'home';
      await this.loadDashboard();
      return;
    }
    this.screen = target;
    if (target === 'home') {
      await this.loadDashboard();
      await this.loadTodos();
    } else if (target === 'history') {
      await this.loadTodos();
    } else if (target === 'mine') {
      await this.loadWorkspace();
    }
  }

  async changeTodoFilter(status: string): Promise<void> {
    this.filterStatus = status;
    await this.loadTodos();
  }

  async changeSortMode(mode: string): Promise<void> {
    this.sortMode = mode;
    this.showSortSettings = false;
    await this.loadDashboard();
    await this.loadTodos();
    this.notice = `任务排序已切换为：${mode}`;
  }

  toggleSortSettings(): void {
    this.showSortSettings = !this.showSortSettings;
  }

  async goBackFromDetail(): Promise<void> {
    let target = this.detailBackScreen.length > 0 ? this.detailBackScreen : 'home';
    await this.navigateTo(target);
  }

  async clearMyData(): Promise<void> {
    if (!this.clearConfirmArmed) {
      this.clearConfirmArmed = true;
      this.notice = '再次点击清除按钮，将只删除当前账号的任务、已完成归档、AI 记录和课程数据';
      return;
    }
    this.loading = true;
    let result = await this.repository.clearUserData(this.user.id);
    if (result.code === 200) {
      this.clearConfirmArmed = false;
      this.currentTodo = new TodoTask();
      this.selectedCompletedTodo = new TodoTask();
      this.currentHistory = new OcrRecord();
      this.completedTodos = [];
      this.selectedHistoryId = 0;
      this.selectedCompletedTodoId = 0;
      this.selectedCompletedDetailVersion += 1;
      this.historyRequestSeq += 1;
      this.draft = new TodoDraft();
      this.aiParsed = new AiParseRecord();
      this.aiParsedList = [];
      this.aiParsedIndex = 0;
      this.parsedDrafts = [];
      this.confirmFormVersion += 1;
      await this.loadWorkspace();
      this.screen = 'home';
      this.notice = '已清除当前账号的所有业务数据，账号仍保留';
    } else {
      this.notice = result.message;
    }
    this.loading = false;
  }

  logout(): void {
    this.user = new UserSession();
    this.screen = 'auth';
    this.clearConfirmArmed = false;
    this.todos = [];
    this.completedTodos = [];
    this.histories = [];
    this.currentTodo = new TodoTask();
    this.selectedCompletedTodo = new TodoTask();
    this.currentHistory = new OcrRecord();
    this.selectedHistoryId = 0;
    this.selectedCompletedTodoId = 0;
    this.selectedCompletedDetailVersion += 1;
    this.historyRequestSeq += 1;
    this.aiParsed = new AiParseRecord();
    this.aiParsedList = [];
    this.aiParsedIndex = 0;
    this.parsedDrafts = [];
    this.confirmFormVersion += 1;
    this.notice = '已退出登录';
  }
}
