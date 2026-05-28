import { SnapTaskApi } from '../api/SnapTaskApi';
import {
  AiParseRecord,
  ApiResponse,
  Course,
  DashboardData,
  OcrRecord,
  TodoDraft,
  TodoTask,
  UserSession
} from './Models';

export class SnapTaskRepository {
  private readonly api: SnapTaskApi = new SnapTaskApi();

  register(username: string, password: string, confirmPassword: string): Promise<ApiResponse<UserSession>> {
    return this.api.register(username, password, confirmPassword);
  }

  login(username: string, password: string): Promise<ApiResponse<UserSession>> {
    return this.api.login(username, password);
  }

  dashboard(userId: number, sortMode: string): Promise<ApiResponse<DashboardData>> {
    return this.api.dashboard(userId, sortMode);
  }

  courses(userId: number): Promise<ApiResponse<Course[]>> {
    return this.api.courses(userId);
  }

  saveCourse(userId: number, courseName: string, teacherName: string, remark: string): Promise<ApiResponse<Course>> {
    return this.api.saveCourse(userId, courseName, teacherName, remark);
  }

  todos(userId: number, status: string, sortMode: string): Promise<ApiResponse<TodoTask[]>> {
    return this.api.todos(userId, status, sortMode);
  }

  todoDetail(userId: number, todoId: number): Promise<ApiResponse<TodoTask>> {
    return this.api.todoDetail(userId, todoId);
  }

  createTodo(draft: TodoDraft): Promise<ApiResponse<TodoTask>> {
    return this.api.createTodo(draft);
  }

  deleteTodo(userId: number, todoId: number): Promise<ApiResponse<boolean>> {
    return this.api.deleteTodo(userId, todoId);
  }

  updateTodoStatus(userId: number, todoId: number, status: string): Promise<ApiResponse<TodoTask>> {
    return this.api.updateTodoStatus(userId, todoId, status);
  }

  createOcrRecord(userId: number, imagePath: string, ocrText: string): Promise<ApiResponse<OcrRecord>> {
    return this.api.createOcrRecord(userId, imagePath, ocrText);
  }

  parseOcr(userId: number, ocrRecordId: number, ocrText: string, apiKey: string): Promise<ApiResponse<AiParseRecord[]>> {
    return this.api.parseOcr(userId, ocrRecordId, ocrText, apiKey);
  }

  confirmParsedTodo(draft: TodoDraft): Promise<ApiResponse<TodoTask>> {
    return this.api.confirmParsedTodo(draft);
  }

  history(userId: number): Promise<ApiResponse<OcrRecord[]>> {
    return this.api.history(userId);
  }

  historyDetail(userId: number, historyId: number): Promise<ApiResponse<OcrRecord>> {
    return this.api.historyDetail(userId, historyId);
  }

  clearUserData(userId: number): Promise<ApiResponse<boolean>> {
    return this.api.clearUserData(userId);
  }
}
