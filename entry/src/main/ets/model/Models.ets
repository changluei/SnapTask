export class UserSession {
  id: number = 0;
  username: string = '';
  createdAt: string = '';
  updatedAt: string = '';
}

export class DashboardData {
  todayCount: number = 0;
  soonCount: number = 0;
  overdueCount: number = 0;
  doneCount: number = 0;
  totalCount: number = 0;
  historyCount: number = 0;
  recentTasks: TodoTask[] = [];
}

export class TodoTask {
  id: number = 0;
  userId: number = 0;
  courseId: number = 0;
  courseName: string = '';
  title: string = '';
  description: string = '';
  taskType: string = '其他';
  platform: string = '其他';
  deadline: string = '';
  priority: string = '中';
  status: string = '待完成';
  sourceType: string = '手动创建';
  sourceRecordId: number = 0;
  createdAt: string = '';
  updatedAt: string = '';
}

export class Course {
  id: number = 0;
  userId: number = 0;
  courseName: string = '';
  teacherName: string = '';
  color: string = '#2563EB';
  remark: string = '';
  createdAt: string = '';
}

export class OcrRecord {
  id: number = 0;
  userId: number = 0;
  imagePath: string = '';
  ocrText: string = '';
  ocrSummary: string = '';
  recognizeStatus: string = '';
  aiStatus: string = '';
  generatedTodoId: number = 0;
  generatedTaskTitle: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  aiRecords: AiParseRecord[] = [];
}

export class AiParseRecord {
  id: number = 0;
  userId: number = 0;
  ocrRecordId: number = 0;
  rawAiResponse: string = '';
  title: string = '';
  courseName: string = '';
  deadline: string = '';
  taskType: string = '其他';
  platform: string = '其他';
  priority: string = '中';
  description: string = '';
  parseStatus: string = '';
  todoGenerated: number = 0;
  createdAt: string = '';
  parserNotice: string = '';
  parserCount: number = 0;
  parserIndex: number = 0;
}

export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

export interface AuthRequest {
  username: string;
  password: string;
  confirmPassword?: string;
}

export interface OcrRequest {
  userId: number;
  imagePath: string;
  ocrText: string;
  recognizeStatus: string;
}

export interface ParseRequest {
  userId: number;
  ocrRecordId: number;
  ocrText: string;
  apiKey: string;
}

export class TodoDraft {
  userId: number = 0;
  aiParseRecordId: number = 0;
  ocrRecordId: number = 0;
  sourceRecordId: number = 0;
  title: string = '';
  courseName: string = '';
  taskType: string = '其他';
  platform: string = '其他';
  deadline: string = '';
  priority: string = '中';
  status: string = '待完成';
  description: string = '';
  sourceType: string = '手动创建';
}

export interface StatusRequest {
  userId: number;
  status: string;
}

export interface CourseRequest {
  userId: number;
  courseName: string;
  teacherName: string;
  remark: string;
}
