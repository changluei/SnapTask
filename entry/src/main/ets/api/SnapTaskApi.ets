import http from '@ohos.net.http';
import {
  AiParseRecord,
  ApiResponse,
  AuthRequest,
  Course,
  CourseRequest,
  DashboardData,
  OcrRecord,
  OcrRequest,
  ParseRequest,
  StatusRequest,
  TodoDraft,
  TodoTask,
  UserSession
} from '../model/Models';

export class SnapTaskApi {
  private readonly baseUrl: string = 'http://10.128.18.93:8080/api';

  private async request<T>(path: string, method: http.RequestMethod, body: string = ''): Promise<ApiResponse<T>> {
    let httpRequest = http.createHttp();
    try {
      let response = await httpRequest.request(`${this.baseUrl}${path}`, {
        method: method,
        connectTimeout: 6000,
        readTimeout: 6000,
        header: {
          'Content-Type': 'application/json; charset=utf-8'
        },
        extraData: body
      });
      let responseText: string = `${response.result}`;
      if (response.responseCode < 200 || response.responseCode >= 300) {
        let failed: ApiResponse<T> = {
          code: response.responseCode,
          message: `后端返回 HTTP ${response.responseCode}: ${responseText}`,
          data: null as T
        };
        return failed;
      }
      try {
        return JSON.parse(responseText) as ApiResponse<T>;
      } catch (parseError) {
        console.error(`SnapTask parse response failed: ${JSON.stringify(parseError)}`);
        let failed: ApiResponse<T> = {
          code: 500,
          message: `后端响应格式异常: ${responseText}`,
          data: null as T
        };
        return failed;
      }
    } catch (error) {
      console.error(`SnapTask request failed: ${JSON.stringify(error)}`);
      let failed: ApiResponse<T> = {
        code: 500,
        message: `请求失败: ${path}。请确认 SpringBoot 已启动、平板和电脑在同一 Wi-Fi。错误: ${JSON.stringify(error)}`,
        data: null as T
      };
      return failed;
    } finally {
      httpRequest.destroy();
    }
  }

  register(username: string, password: string, confirmPassword: string): Promise<ApiResponse<UserSession>> {
    let body: AuthRequest = {
      username: username,
      password: password,
      confirmPassword: confirmPassword
    };
    return this.request<UserSession>('/auth/register', http.RequestMethod.POST, JSON.stringify(body));
  }

  login(username: string, password: string): Promise<ApiResponse<UserSession>> {
    let body: AuthRequest = {
      username: username,
      password: password
    };
    return this.request<UserSession>('/auth/login', http.RequestMethod.POST, JSON.stringify(body));
  }

  dashboard(userId: number, sortMode: string): Promise<ApiResponse<DashboardData>> {
    return this.request<DashboardData>(`/dashboard?userId=${userId}&sortMode=${encodeURIComponent(sortMode)}`, http.RequestMethod.GET);
  }

  me(userId: number): Promise<ApiResponse<UserSession>> {
    return this.request<UserSession>(`/me?userId=${userId}`, http.RequestMethod.GET);
  }

  courses(userId: number): Promise<ApiResponse<Course[]>> {
    return this.request<Course[]>(`/courses?userId=${userId}`, http.RequestMethod.GET);
  }

  saveCourse(userId: number, courseName: string, teacherName: string, remark: string): Promise<ApiResponse<Course>> {
    let body: CourseRequest = {
      userId: userId,
      courseName: courseName,
      teacherName: teacherName,
      remark: remark
    };
    return this.request<Course>('/courses', http.RequestMethod.POST, JSON.stringify(body));
  }

  todos(userId: number, status: string, sortMode: string): Promise<ApiResponse<TodoTask[]>> {
    return this.request<TodoTask[]>(`/todos?userId=${userId}&status=${encodeURIComponent(status)}&sortMode=${encodeURIComponent(sortMode)}`, http.RequestMethod.GET);
  }

  todoDetail(userId: number, id: number): Promise<ApiResponse<TodoTask>> {
    return this.request<TodoTask>(`/todos/${id}?userId=${userId}`, http.RequestMethod.GET);
  }

  createTodo(draft: TodoDraft): Promise<ApiResponse<TodoTask>> {
    return this.request<TodoTask>('/todos', http.RequestMethod.POST, JSON.stringify(draft));
  }

  updateTodo(id: number, draft: TodoDraft): Promise<ApiResponse<TodoTask>> {
    return this.request<TodoTask>(`/todos/${id}`, http.RequestMethod.PUT, JSON.stringify(draft));
  }

  deleteTodo(userId: number, id: number): Promise<ApiResponse<boolean>> {
    let body: StatusRequest = {
      userId: userId,
      status: ''
    };
    return this.request<boolean>(`/todos/${id}/delete`, http.RequestMethod.POST, JSON.stringify(body));
  }

  updateTodoStatus(userId: number, id: number, status: string): Promise<ApiResponse<TodoTask>> {
    let body: StatusRequest = {
      userId: userId,
      status: status
    };
    return this.request<TodoTask>(`/todos/${id}/status`, http.RequestMethod.POST, JSON.stringify(body));
  }

  createOcrRecord(userId: number, imagePath: string, ocrText: string): Promise<ApiResponse<OcrRecord>> {
    let body: OcrRequest = {
      userId: userId,
      imagePath: imagePath,
      ocrText: ocrText,
      recognizeStatus: '成功'
    };
    return this.request<OcrRecord>('/ocr/records', http.RequestMethod.POST, JSON.stringify(body));
  }

  parseOcr(userId: number, ocrRecordId: number, ocrText: string, apiKey: string): Promise<ApiResponse<AiParseRecord[]>> {
    let body: ParseRequest = {
      userId: userId,
      ocrRecordId: ocrRecordId,
      ocrText: ocrText,
      apiKey: apiKey
    };
    return this.request<AiParseRecord[]>('/ai/parse', http.RequestMethod.POST, JSON.stringify(body));
  }

  confirmParsedTodo(draft: TodoDraft): Promise<ApiResponse<TodoTask>> {
    return this.request<TodoTask>('/ai/confirm', http.RequestMethod.POST, JSON.stringify(draft));
  }

  history(userId: number): Promise<ApiResponse<OcrRecord[]>> {
    return this.request<OcrRecord[]>(`/ocr/records?userId=${userId}`, http.RequestMethod.GET);
  }

  historyDetail(userId: number, id: number): Promise<ApiResponse<OcrRecord>> {
    return this.request<OcrRecord>(`/ocr/records/${id}?userId=${userId}`, http.RequestMethod.GET);
  }

  clearUserData(userId: number): Promise<ApiResponse<boolean>> {
    let body: StatusRequest = {
      userId: userId,
      status: ''
    };
    return this.request<boolean>(`/users/${userId}/data/clear`, http.RequestMethod.POST, JSON.stringify(body));
  }
}
