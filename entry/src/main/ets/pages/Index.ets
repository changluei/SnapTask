import { SnapTaskViewModel } from '../viewmodel/SnapTaskViewModel';
import { AiParseRecord, TodoTask } from '../model/Models';

@Entry
@ComponentV2
struct Index {
  @Local vm: SnapTaskViewModel = new SnapTaskViewModel();
  @Local pageWidth: number = 0;
  @Local pageHeight: number = 0;

  safeText(value: string): string {
    let text = `${value}`;
    if (text === 'null' || text === 'undefined') {
      return '';
    }
    return text;
  }

  displayText(value: string): string {
    let text = this.safeText(value);
    return text.length > 0 ? text : '未设置';
  }

  displayPlatform(value: string): string {
    let text = this.safeText(this.vm.normalizePlatform(value));
    return text.length > 0 ? text : '未设置';
  }

  isHistorySelected(id: number): boolean {
    return this.vm.selectedCompletedTodoId === id;
  }

  updateViewport(area: Area): void {
    if (typeof area.width === 'number') {
      this.pageWidth = area.width;
    }
    if (typeof area.height === 'number') {
      this.pageHeight = area.height;
    }
  }

  isLandscape(): boolean {
    return this.pageWidth > this.pageHeight && this.pageWidth >= 720;
  }

  isNavSelected(target: string): boolean {
    if (this.vm.screen === target) {
      return true;
    }
    if (this.vm.screen === 'confirm' && target === 'scan') {
      return true;
    }
    if (this.vm.screen === 'detail' && this.vm.detailBackScreen === target) {
      return true;
    }
    return false;
  }

  authPanelWidth(): string {
    return this.isLandscape() ? '46%' : '88%';
  }

  @Builder
  Header() {
    Row() {
      Column() {
        Text('SnapTask')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#71838F')
        Text(this.vm.notice)
          .fontSize(12)
          .fontColor('#71838F')
          .margin({ top: 4 })
      }
      .layoutWeight(1)

      if (this.vm.user.id > 0) {
        Text(this.vm.user.username)
          .fontSize(13)
          .fontColor('#71838F')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#D6C7B2')
          .borderRadius(8)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 18, right: 18, top: 18, bottom: 14 })
    .backgroundColor('#E8EADC')
  }

  @Builder
  AuthView() {
    Column() {
      Blank().height(44)
      Text('SnapTask')
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#71838F')
      Text('截图识别课程任务，自动生成 Todo')
        .fontSize(14)
        .fontColor('#71838F')
        .margin({ top: 8, bottom: 26 })

      Column() {
        Row() {
          Button('登录')
            .layoutWeight(1)
            .height(38)
            .fontColor(this.vm.authMode === 'login' ? '#E8EADC' : '#71838F')
            .backgroundColor(this.vm.authMode === 'login' ? '#71838F' : '#D6C7B2')
            .borderRadius(8)
            .onClick(() => {
              this.vm.authMode = 'login';
            })
          Button('注册')
            .layoutWeight(1)
            .height(38)
            .fontColor(this.vm.authMode === 'register' ? '#E8EADC' : '#71838F')
            .backgroundColor(this.vm.authMode === 'register' ? '#71838F' : '#D6C7B2')
            .borderRadius(8)
            .margin({ left: 10 })
            .onClick(() => {
              this.vm.authMode = 'register';
            })
        }
        .width('100%')

        if (this.vm.authMode === 'login') {
          TextInput({ text: this.vm.loginUsername, placeholder: '用户名' })
            .height(46)
            .width('100%')
            .margin({ top: 18 })
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .onChange((value: string) => {
              this.vm.loginUsername = value;
            })
          TextInput({ text: this.vm.loginPassword, placeholder: '密码' })
            .height(46)
            .width('100%')
            .margin({ top: 12 })
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .type(InputType.Password)
            .onChange((value: string) => {
              this.vm.loginPassword = value;
            })
          Button(this.vm.loading ? '登录中' : '登录')
            .height(46)
            .width('100%')
            .fontColor('#E8EADC')
            .backgroundColor('#71838F')
            .borderRadius(8)
            .margin({ top: 18 })
            .enabled(!this.vm.loading)
            .onClick(() => {
              this.vm.doLogin();
            })
        } else {
          TextInput({ text: this.vm.registerUsername, placeholder: '用户名' })
            .height(46)
            .width('100%')
            .margin({ top: 18 })
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .onChange((value: string) => {
              this.vm.registerUsername = value;
            })
          TextInput({ text: this.vm.registerPassword, placeholder: '密码' })
            .height(46)
            .width('100%')
            .margin({ top: 12 })
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .type(InputType.Password)
            .onChange((value: string) => {
              this.vm.registerPassword = value;
            })
          TextInput({ text: this.vm.registerConfirm, placeholder: '确认密码' })
            .height(46)
            .width('100%')
            .margin({ top: 12 })
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .type(InputType.Password)
            .onChange((value: string) => {
              this.vm.registerConfirm = value;
            })
          Button(this.vm.loading ? '注册中' : '注册')
            .height(46)
            .width('100%')
            .fontColor('#E8EADC')
            .backgroundColor('#71838F')
            .borderRadius(8)
            .margin({ top: 18 })
            .enabled(!this.vm.loading)
            .onClick(() => {
              this.vm.doRegister();
            })
        }
      }
      .padding(18)
      .width(this.authPanelWidth())
      .backgroundColor('#E8EADC')
      .borderRadius(8)
      .borderWidth(1)
      .borderColor('#D6C7B2')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E8EADC')
  }

  @Builder
  HomeView() {
    Scroll() {
      Column() {
        Row() {
          this.StatCard('今日待办', this.vm.dashboard.todayCount.toString(), '#E8EADC', '#71838F')
          this.StatCard('即将截止', this.vm.dashboard.soonCount.toString(), '#D6C7B2', '#71838F')
        }
        Row() {
          this.StatCard('已逾期', this.vm.dashboard.overdueCount.toString(), '#E5CC96', '#D39394')
          this.StatCard('已完成', this.vm.dashboard.doneCount.toString(), '#E5CC96', '#D39394')
        }
        .margin({ top: 10 })

        Column() {
          Row() {
            Column() {
              Text('任务排序')
                .fontSize(13)
                .fontColor('#71838F')
              Text(this.vm.sortMode)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#71838F')
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            Button(this.vm.showSortSettings ? '收起' : '设置')
              .height(34)
              .fontSize(13)
              .fontColor('#71838F')
              .backgroundColor('#D6C7B2')
              .borderRadius(8)
              .onClick(() => {
                this.vm.toggleSortSettings();
              })
          }
          .width('100%')

          if (this.vm.showSortSettings) {
            Row() {
              this.SortButton('截止时间')
              this.SortButton('优先级')
            }
            .margin({ top: 12 })
            Row() {
              this.SortButton('开始时间')
              this.SortButton('创建时间')
            }
            .margin({ top: 8 })
          }
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#E8EADC')
        .borderRadius(8)
        .borderWidth(1)
        .borderColor('#D6C7B2')
        .margin({ top: 16 })

        this.SectionTitle('全部任务')
        if (this.vm.todos.length === 0) {
          this.EmptyBlock('暂无待完成任务，已完成的任务会进入历史')
        } else {
          ForEach(this.vm.todos, (item: TodoTask) => {
            this.TodoCard(item)
          }, (item: TodoTask) => item.id.toString())
        }
      }
      .padding(16)
    }
  }

  @Builder
  StatCard(label: string, value: string, bg: string, fg: string) {
    Column() {
      Text(value)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(fg)
      Text(label)
        .fontSize(13)
        .fontColor('#71838F')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .height(86)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16 })
    .backgroundColor(bg)
    .borderRadius(8)
    .borderWidth(1)
    .borderColor('#D6C7B2')
    .margin({ right: 5, left: 5 })
  }

  @Builder
  ScanView() {
    Scroll() {
      Column() {
        Column() {
          Text('课程截图识别')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#71838F')
          Text(this.vm.selectedImage)
            .fontSize(13)
            .fontColor('#71838F')
            .margin({ top: 8 })
          if (this.vm.selectedImageUri.length > 0) {
            Image(this.vm.selectedImageUri)
              .width('100%')
              .height(180)
              .objectFit(ImageFit.Contain)
              .backgroundColor('#E8EADC')
              .borderRadius(8)
              .borderWidth(1)
              .borderColor('#D6C7B2')
              .margin({ top: 12 })
          } else {
            Column() {
              Text('选择一张雨课堂、小雅或课程通知截图')
                .fontSize(14)
                .fontColor('#71838F')
            }
            .width('100%')
            .height(120)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .margin({ top: 12 })
          }
          Button('选择本机截图')
            .height(40)
            .width('100%')
            .fontColor('#E8EADC')
            .backgroundColor('#71838F')
            .borderRadius(8)
            .margin({ top: 14 })
            .onClick(() => {
              this.vm.pickDeviceImage();
            })
          Button(this.vm.recognizing ? '识别中' : '开始本地 OCR')
            .height(40)
            .width('100%')
            .fontColor('#E8EADC')
            .backgroundColor('#71838F')
            .borderRadius(8)
            .margin({ top: 10 })
            .enabled(!this.vm.recognizing)
            .onClick(() => {
              this.vm.runOcr();
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#E8EADC')
        .borderRadius(8)
        .borderWidth(1)
        .borderColor('#D6C7B2')

        Column() {
          Text('OCR 原文')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#71838F')
          TextArea({ text: this.vm.ocrText, placeholder: '这里会显示 OCR 文本，也可以手动粘贴课程通知内容' })
            .width('100%')
            .height(170)
            .fontSize(14)
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.vm.ocrText = value;
            })
          Text(this.vm.deepSeekApiKey.trim().length > 0 ? 'DeepSeek: 将调用 deepseek-chat' : 'DeepSeek: 未填写 Key，将使用本地规则')
            .fontSize(12)
            .fontColor(this.vm.deepSeekApiKey.trim().length > 0 ? '#71838F' : '#D39394')
            .width('100%')
            .margin({ top: 8 })
          Button(this.vm.loading ? '解析中' : '下一步：AI 解析')
            .height(44)
            .width('100%')
            .fontColor('#E8EADC')
            .backgroundColor('#71838F')
            .borderRadius(8)
            .margin({ top: 14 })
            .enabled(!this.vm.loading)
            .onClick(() => {
              this.vm.parseOcr();
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#E8EADC')
        .borderRadius(8)
        .borderWidth(1)
        .borderColor('#D6C7B2')
        .margin({ top: 12 })
      }
      .padding(16)
    }
  }

  @Builder
  ConfirmView() {
    Scroll() {
      Column() {
        this.SectionTitle(this.vm.draft.sourceType === '手动创建' ? '手动创建 Todo' : '确认 AI 解析结果')
        if (this.vm.aiParsedList.length > 1) {
          Column() {
            ForEach(this.vm.aiParsedList, (item: AiParseRecord) => {
              Text(`${item.parserIndex}. ${this.safeText(item.title)} · ${this.safeText(item.deadline)}`)
                .fontSize(12)
                .fontColor(item.id === this.vm.aiParsed.id ? '#71838F' : '#71838F')
                .width('100%')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ bottom: 4 })
            }, (item: AiParseRecord) => item.id.toString())
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#E8EADC')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .margin({ top: 8, bottom: 8 })

          Row() {
            Button('上一个')
              .height(34)
              .fontSize(13)
              .fontColor('#71838F')
              .backgroundColor('#D6C7B2')
              .borderRadius(8)
              .enabled(this.vm.aiParsedIndex > 0 && !this.vm.loading)
              .onClick(() => {
                this.vm.previousParsed();
              })
            Text(`第 ${this.vm.aiParsedIndex + 1}/${this.vm.aiParsedList.length} 个任务`)
              .fontSize(13)
              .fontColor('#71838F')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Button('下一个')
              .height(34)
              .fontSize(13)
              .fontColor('#71838F')
              .backgroundColor('#D6C7B2')
              .borderRadius(8)
              .enabled(this.vm.aiParsedIndex < this.vm.aiParsedList.length - 1 && !this.vm.loading)
              .onClick(() => {
                this.vm.nextParsed();
              })
          }
          .width('100%')
          .margin({ top: 8, bottom: 4 })
        }

        if (this.vm.confirmFormVersion % 2 === 0) {
          this.ConfirmDraftEditor()
        } else {
          this.ConfirmDraftEditor()
        }

        this.ConfirmActions()

        if (this.vm.ocrText.length > 0) {
          this.SectionTitle('OCR 原文')
          Text(this.vm.ocrText)
            .fontSize(13)
            .fontColor('#71838F')
            .width('100%')
            .padding(12)
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
        }
      }
      .padding(16)
    }
  }

  @Builder
  ConfirmDraftEditor() {
    Column() {
      this.DraftInput('任务标题', 'title', this.vm.draft.title)
      this.DraftInput('课程名称', 'courseName', this.vm.draft.courseName)
      this.DraftInput('截止时间', 'deadline', this.vm.draft.deadline)

      Row() {
        this.ChoiceButton('作业', this.vm.draft.taskType, 'taskType')
        this.ChoiceButton('实验', this.vm.draft.taskType, 'taskType')
        this.ChoiceButton('报告', this.vm.draft.taskType, 'taskType')
        this.ChoiceButton('测验', this.vm.draft.taskType, 'taskType')
      }
      .margin({ top: 8 })

      Row() {
        this.ChoiceButton('小雅', this.vm.draft.platform, 'platform')
        this.ChoiceButton('雨课堂', this.vm.draft.platform, 'platform')
        this.ChoiceButton('飞书', this.vm.draft.platform, 'platform')
        this.ChoiceButton('其他', this.vm.draft.platform, 'platform')
      }
      .margin({ top: 8 })

      Row() {
        this.ChoiceButton('高', this.vm.draft.priority, 'priority')
        this.ChoiceButton('中', this.vm.draft.priority, 'priority')
        this.ChoiceButton('低', this.vm.draft.priority, 'priority')
      }
      .margin({ top: 8 })

      TextArea({ text: this.vm.draft.description, placeholder: '任务说明' })
        .width('100%')
        .height(110)
        .fontSize(14)
        .backgroundColor('#E8EADC')
        .borderRadius(8)
        .borderWidth(1)
        .borderColor('#D6C7B2')
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.vm.setDraftField('description', value);
        })
    }
    .width('100%')
  }

  @Builder
  ConfirmActions() {
    Column() {
      Button(this.vm.loading ? '保存中' : (this.vm.aiParsedList.length > 1 ? '保存当前 Todo' : '确认生成 Todo'))
        .height(42)
        .width('100%')
        .fontColor('#E8EADC')
        .backgroundColor('#71838F')
        .borderRadius(8)
        .borderWidth(1)
        .borderColor('#D6C7B2')
        .margin({ top: 14 })
        .enabled(!this.vm.loading)
        .onClick(() => {
          this.vm.saveDraft();
        })

        if (this.vm.aiParsedList.length > 1) {
          Button(this.vm.loading ? '保存中' : '一键生成全部 Todo')
            .height(42)
            .width('100%')
            .fontColor('#71838F')
            .backgroundColor('#D6C7B2')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .margin({ top: 10 })
            .enabled(!this.vm.loading)
            .onClick(() => {
              this.vm.saveAllParsedDrafts();
            })
      }
    }
    .width('100%')
  }

  @Builder
  ManualView() {
    Scroll() {
      Column() {
        this.SectionTitle('手动创建 Todo')
        Text('直接填写课程任务信息，保存后会进入数据库。')
          .fontSize(13)
          .fontColor('#71838F')
          .width('100%')
          .margin({ bottom: 4 })

        this.DraftInput('任务标题', 'title', this.vm.draft.title)
        this.DraftInput('课程名称', 'courseName', this.vm.draft.courseName)
        this.DraftInput('截止时间', 'deadline', this.vm.draft.deadline)

        Row() {
          this.ChoiceButton('作业', this.vm.draft.taskType, 'taskType')
          this.ChoiceButton('实验', this.vm.draft.taskType, 'taskType')
          this.ChoiceButton('报告', this.vm.draft.taskType, 'taskType')
          this.ChoiceButton('测验', this.vm.draft.taskType, 'taskType')
        }
        .margin({ top: 8 })

        Row() {
          this.ChoiceButton('小雅', this.vm.draft.platform, 'platform')
          this.ChoiceButton('雨课堂', this.vm.draft.platform, 'platform')
          this.ChoiceButton('飞书', this.vm.draft.platform, 'platform')
          this.ChoiceButton('其他', this.vm.draft.platform, 'platform')
        }
        .margin({ top: 8 })

        Row() {
          this.ChoiceButton('高', this.vm.draft.priority, 'priority')
          this.ChoiceButton('中', this.vm.draft.priority, 'priority')
          this.ChoiceButton('低', this.vm.draft.priority, 'priority')
        }
        .margin({ top: 8 })

        TextArea({ text: this.vm.draft.description, placeholder: '任务说明' })
          .width('100%')
          .height(120)
          .fontSize(14)
          .backgroundColor('#E8EADC')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .margin({ top: 12 })
          .onChange((value: string) => {
            this.vm.setDraftField('description', value);
          })

        Button(this.vm.loading ? '保存中' : '保存 Todo')
          .height(44)
          .width('100%')
          .fontColor('#E8EADC')
          .backgroundColor('#71838F')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .margin({ top: 16 })
          .enabled(!this.vm.loading)
          .onClick(() => {
            this.vm.saveDraft();
          })
      }
      .padding(16)
    }
  }

  @Builder
  DraftInput(label: string, field: string, value: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#71838F')
      TextInput({ text: value })
        .height(42)
        .width('100%')
        .fontSize(14)
        .backgroundColor('#E8EADC')
        .borderRadius(8)
        .borderWidth(1)
        .borderColor('#D6C7B2')
        .margin({ top: 6 })
        .onChange((input: string) => {
          this.vm.setDraftField(field, input);
        })
    }
    .width('100%')
    .margin({ top: 10 })
  }

  @Builder
  ChoiceButton(label: string, current: string, field: string) {
    Button(label)
      .layoutWeight(1)
      .height(34)
      .fontSize(12)
      .fontColor(this.choiceSelected(label, current, field) ? '#E8EADC' : '#71838F')
      .backgroundColor(this.choiceSelected(label, current, field) ? '#71838F' : '#D6C7B2')
      .borderRadius(8)
      .borderWidth(1)
      .borderColor(this.choiceSelected(label, current, field) ? '#71838F' : '#D6C7B2')
      .margin({ right: 6 })
      .onClick(() => {
        this.vm.setDraftField(field, label);
      })
  }

  choiceSelected(label: string, current: string, field: string): boolean {
    if (field === 'taskType') {
      return this.vm.draft.taskType === label;
    }
    if (field === 'platform') {
      return this.vm.normalizePlatform(this.vm.draft.platform) === label;
    }
    if (field === 'priority') {
      return this.vm.draft.priority === label;
    }
    return current === label;
  }

  @Builder
  SortButton(label: string) {
    Button(label)
      .layoutWeight(1)
      .height(34)
      .fontSize(12)
      .fontColor(this.vm.sortMode === label ? '#E8EADC' : '#71838F')
      .backgroundColor(this.vm.sortMode === label ? '#71838F' : '#E8EADC')
      .borderRadius(8)
      .borderWidth(1)
      .borderColor('#D6C7B2')
      .margin({ right: 6 })
      .onClick(async () => {
        await this.vm.changeSortMode(label);
      })
  }

  @Builder
  TodosView() {
    Column() {
      Row() {
        ForEach(['全部', '待完成', '进行中', '已完成', '已逾期'], (item: string) => {
          Button(item)
            .height(34)
            .fontSize(12)
            .fontColor(this.vm.filterStatus === item ? '#E8EADC' : '#71838F')
            .backgroundColor(this.vm.filterStatus === item ? '#71838F' : '#D6C7B2')
            .borderRadius(8)
            .margin({ right: 6 })
            .onClick(async () => {
              await this.vm.changeTodoFilter(item);
            })
        })
      }
      .width('100%')
      .padding({ left: 16, top: 12, right: 10 })

      Scroll() {
        Column() {
          if (this.vm.todos.length === 0) {
            this.EmptyBlock('暂无任务')
          } else {
            ForEach(this.vm.todos, (item: TodoTask) => {
              this.TodoCard(item)
            }, (item: TodoTask) => item.id.toString())
          }
        }
        .padding(16)
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
    }
  }

  @Builder
  TodoCard(item: TodoTask) {
    Column() {
      Row() {
        this.CompleteCheck(item)

        Column() {
          Row() {
            Text(this.displayText(item.title))
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#71838F')
              .layoutWeight(1)
            Text(item.priority)
              .fontSize(12)
              .fontColor(item.priority === '高' ? '#D39394' : '#71838F')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(item.priority === '高' ? '#E5CC96' : '#D6C7B2')
              .borderRadius(8)
          }
          Text(`${this.displayText(item.courseName)} · ${this.displayText(item.taskType)} · ${this.displayPlatform(item.platform)}`)
            .fontSize(13)
            .fontColor('#71838F')
            .margin({ top: 6 })
          Text(`截止：${this.displayText(item.deadline)} · ${this.displayText(item.status)}`)
            .fontSize(13)
            .fontColor(item.status === '已逾期' ? '#D39394' : '#71838F')
            .margin({ top: 5 })
        }
        .layoutWeight(1)
        .onClick(() => {
          this.vm.openTodo(item);
        })
      }
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#E8EADC')
    .borderRadius(8)
    .borderWidth(1)
    .borderColor('#D6C7B2')
    .margin({ bottom: 10 })
  }

  @Builder
  CompleteCheck(item: TodoTask) {
    Button('')
      .width(24)
      .height(24)
      .backgroundColor('#E8EADC')
      .borderRadius(6)
      .borderWidth(2)
      .borderColor('#71838F')
      .margin({ right: 12, top: 2 })
      .enabled(!this.vm.loading)
      .onClick(async () => {
        await this.vm.completeTodo(item);
      })
  }

  @Builder
  CompletedTaskCard(item: TodoTask) {
    Column() {
      Row() {
        Text(this.displayText(item.title))
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#71838F')
          .layoutWeight(1)
        Text('已完成')
          .fontSize(12)
          .fontColor('#71838F')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#D6C7B2')
          .borderRadius(8)
      }
      Text(`${this.displayText(item.courseName)} · ${this.displayText(item.taskType)} · ${this.displayPlatform(item.platform)}`)
        .fontSize(13)
        .fontColor('#71838F')
        .margin({ top: 6 })
      Text(`完成归档：${this.displayText(item.updatedAt)}`)
        .fontSize(13)
        .fontColor('#71838F')
        .margin({ top: 5 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.isHistorySelected(item.id) ? '#D6C7B2' : '#E8EADC')
    .borderRadius(8)
    .borderWidth(1)
    .borderColor(this.isHistorySelected(item.id) ? '#71838F' : '#D6C7B2')
    .margin({ bottom: 10 })
    .onClick(() => {
      this.vm.selectCompletedTodo(item);
    })
  }

  @Builder
  CompletedHistoryDetail(item: TodoTask) {
    Column() {
      this.SectionTitle('完成详情')
      Column() {
        Row() {
          Text('任务标题')
            .fontSize(13)
            .fontColor('#71838F')
            .width(82)
          Text(this.displayText(item.title))
            .fontSize(14)
            .fontColor('#71838F')
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .borderColor('#D6C7B2')
        .borderWidth({ bottom: 1 })

        Row() {
          Text('课程名称')
            .fontSize(13)
            .fontColor('#71838F')
            .width(82)
          Text(this.displayText(item.courseName))
            .fontSize(14)
            .fontColor('#71838F')
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .borderColor('#D6C7B2')
        .borderWidth({ bottom: 1 })

        Row() {
          Text('任务类型')
            .fontSize(13)
            .fontColor('#71838F')
            .width(82)
          Text(this.displayText(item.taskType))
            .fontSize(14)
            .fontColor('#71838F')
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .borderColor('#D6C7B2')
        .borderWidth({ bottom: 1 })

        Row() {
          Text('提交平台')
            .fontSize(13)
            .fontColor('#71838F')
            .width(82)
          Text(this.displayPlatform(item.platform))
            .fontSize(14)
            .fontColor('#71838F')
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .borderColor('#D6C7B2')
        .borderWidth({ bottom: 1 })

        Row() {
          Text('截止时间')
            .fontSize(13)
            .fontColor('#71838F')
            .width(82)
          Text(this.displayText(item.deadline))
            .fontSize(14)
            .fontColor('#71838F')
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .borderColor('#D6C7B2')
        .borderWidth({ bottom: 1 })

        Row() {
          Text('完成时间')
            .fontSize(13)
            .fontColor('#71838F')
            .width(82)
          Text(this.displayText(item.updatedAt))
            .fontSize(14)
            .fontColor('#71838F')
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .borderColor('#D6C7B2')
        .borderWidth({ bottom: 1 })

        Row() {
          Text('优先级')
            .fontSize(13)
            .fontColor('#71838F')
            .width(82)
          Text(this.displayText(item.priority))
            .fontSize(14)
            .fontColor('#71838F')
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 10, bottom: 10 })
        .borderColor('#D6C7B2')
        .borderWidth({ bottom: 1 })
      }
      .width('100%')

      Text(this.displayText(item.description))
        .fontSize(14)
        .fontColor('#71838F')
        .width('100%')
        .padding(14)
        .backgroundColor('#E8EADC')
        .borderRadius(8)
        .borderWidth(1)
        .borderColor('#D6C7B2')
        .margin({ top: 12 })
    }
    .width('100%')
  }

  @Builder
  DetailView() {
    Scroll() {
      Column() {
        Button('返回')
          .height(34)
          .fontSize(13)
          .fontColor('#71838F')
          .backgroundColor('#D6C7B2')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 12 })
          .onClick(async () => {
            await this.vm.goBackFromDetail();
          })
        Text(this.displayText(this.vm.currentTodo.title))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#71838F')
        Text(`${this.displayText(this.vm.currentTodo.courseName)} / ${this.displayText(this.vm.currentTodo.taskType)} / ${this.displayPlatform(this.vm.currentTodo.platform)}`)
          .fontSize(14)
          .fontColor('#71838F')
          .margin({ top: 8 })
        this.InfoLine('截止时间', this.vm.currentTodo.deadline)
        this.InfoLine('任务状态', this.vm.currentTodo.status)
        this.InfoLine('优先级', this.vm.currentTodo.priority)
        this.InfoLine('来源', this.vm.currentTodo.sourceType)
        this.InfoLine('创建时间', this.vm.currentTodo.createdAt)
        Text(this.displayText(this.vm.currentTodo.description))
          .fontSize(14)
          .fontColor('#71838F')
          .width('100%')
          .padding(14)
          .backgroundColor('#E8EADC')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .margin({ top: 12 })

        Button('删除任务')
          .height(40)
          .width('100%')
          .fontColor('#D39394')
          .backgroundColor('#E5CC96')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .margin({ top: 12 })
          .onClick(() => {
            this.vm.removeCurrentTodo();
          })
      }
      .padding(16)
    }
  }

  @Builder
  HistoryView() {
    Scroll() {
      Column() {
        this.SectionTitle('已完成任务')
        if (this.vm.completedTodos.length === 0) {
          this.EmptyBlock('还没有已完成任务')
        } else {
          ForEach(this.vm.completedTodos, (item: TodoTask) => {
            this.CompletedTaskCard(item)
          }, (item: TodoTask) => item.id.toString())
        }

        if (this.vm.selectedCompletedTodo.id > 0) {
          if (this.vm.selectedCompletedDetailVersion % 2 === 0) {
            this.CompletedHistoryDetail(this.vm.selectedCompletedTodo)
          } else {
            this.CompletedHistoryDetail(this.vm.selectedCompletedTodo)
          }
        }
      }
      .padding(16)
    }
  }

  @Builder
  MineView() {
    Scroll() {
      Column() {
        this.SectionTitle('我的')
        this.InfoLine('用户名', this.vm.user.username)
        this.InfoLine('任务总数', this.vm.dashboard.totalCount.toString())
        this.InfoLine('已完成', this.vm.completedTodos.length.toString())
        this.InfoLine('未完成', this.vm.todos.length.toString())
        this.InfoLine('DeepSeek API', this.vm.deepSeekApiKey.length > 0 ? '已填写，将用于下一次 AI 解析' : '未填写，后端会使用本地规则解析')

        this.SectionTitle('DeepSeek 设置')
        TextInput({ text: this.vm.deepSeekApiKey, placeholder: '粘贴 DeepSeek API Key' })
          .height(42)
          .width('100%')
          .backgroundColor('#E8EADC')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .type(InputType.Password)
          .onChange((value: string) => {
            this.vm.deepSeekApiKey = value;
          })
        Text('Key 只会随本次解析请求发送给后端，不写进应用源码。')
          .fontSize(12)
          .fontColor('#71838F')
          .width('100%')
          .margin({ top: 8 })

        this.SectionTitle('数据')
        Button(this.vm.clearConfirmArmed ? '再次点击确认清除' : '清除本人所有数据')
          .height(42)
          .width('100%')
          .fontColor('#D39394')
          .backgroundColor('#E5CC96')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .enabled(!this.vm.loading)
          .onClick(async () => {
            await this.vm.clearMyData();
          })
        Text('只删除当前账号的任务、已完成归档、AI 记录和课程数据，不删除账号。')
          .fontSize(12)
          .fontColor('#71838F')
          .width('100%')
          .margin({ top: 8 })

        Button('退出登录')
          .height(42)
          .width('100%')
          .fontColor('#D39394')
          .backgroundColor('#E5CC96')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .margin({ top: 18 })
          .onClick(() => {
            this.vm.logout();
          })
      }
      .padding(16)
    }
  }

  @Builder
  PortraitShell() {
    Column() {
      this.Header()
      Column() {
        if (this.vm.screen === 'home') {
          this.HomeView()
        } else if (this.vm.screen === 'scan') {
          this.ScanView()
        } else if (this.vm.screen === 'confirm') {
          this.ConfirmView()
        } else if (this.vm.screen === 'manual') {
          this.ManualView()
        } else if (this.vm.screen === 'detail') {
          this.DetailView()
        } else if (this.vm.screen === 'history') {
          this.HistoryView()
        } else {
          this.MineView()
        }
      }
      .layoutWeight(1)
      .backgroundColor('#E8EADC')
      this.NavBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E8EADC')
  }

  @Builder
  LandscapeHeader() {
    Row() {
      Column() {
        Text('SnapTask')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#71838F')
        Text(this.vm.notice)
          .fontSize(12)
          .fontColor('#71838F')
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)

      if (this.vm.user.id > 0) {
        Text(this.vm.user.username)
          .fontSize(13)
          .fontColor('#71838F')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor('#D6C7B2')
          .borderRadius(8)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 18, right: 18, top: 16, bottom: 12 })
    .backgroundColor('#E8EADC')
  }

  @Builder
  SideNav() {
    Column() {
      Column() {
        Text('SnapTask')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#71838F')
        Text(this.vm.user.id > 0 ? this.vm.user.username : '未登录')
          .fontSize(12)
          .fontColor('#71838F')
          .margin({ top: 6 })
      }
      .width('100%')
      .padding({ top: 20, bottom: 18, left: 10, right: 10 })

      this.SideNavButton('首页', 'home')
      this.SideNavButton('识别', 'scan')
      this.SideNavButton('手动', 'manual')
      this.SideNavButton('历史', 'history')
      this.SideNavButton('我的', 'mine')

      Blank().layoutWeight(1)
    }
    .width(156)
    .height('100%')
    .padding({ top: 6, bottom: 12, left: 10, right: 10 })
    .backgroundColor('#E8EADC')
  }

  @Builder
  SideNavButton(label: string, target: string) {
    Button(label)
      .width('100%')
      .height(42)
      .fontSize(13)
      .fontColor(this.isNavSelected(target) ? '#E8EADC' : '#71838F')
      .backgroundColor(this.isNavSelected(target) ? '#71838F' : '#E8EADC')
      .borderRadius(8)
      .borderWidth(1)
      .borderColor(this.isNavSelected(target) ? '#71838F' : '#D6C7B2')
      .margin({ top: 6 })
      .onClick(async () => {
        await this.vm.navigateTo(target);
      })
  }

  @Builder
  LandscapeShell() {
    Row() {
      this.SideNav()
      Column() {
        this.LandscapeHeader()
        Column() {
          if (this.vm.screen === 'home') {
            this.LandscapeHomeView()
          } else if (this.vm.screen === 'scan') {
            this.LandscapeScanView()
          } else if (this.vm.screen === 'confirm') {
            this.LandscapeConfirmView()
          } else if (this.vm.screen === 'manual') {
            this.LandscapeManualView()
          } else if (this.vm.screen === 'detail') {
            this.LandscapeDetailView()
          } else if (this.vm.screen === 'history') {
            this.LandscapeHistoryView()
          } else {
            this.LandscapeMineView()
          }
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .backgroundColor('#E8EADC')
      }
      .layoutWeight(1)
      .height('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
    .backgroundColor('#E8EADC')
  }

  @Builder
  LandscapeHomeView() {
    Row() {
      Scroll() {
        Column() {
          Row() {
            this.StatCard('今日待办', this.vm.dashboard.todayCount.toString(), '#E8EADC', '#71838F')
            this.StatCard('即将截止', this.vm.dashboard.soonCount.toString(), '#D6C7B2', '#71838F')
          }
          Row() {
            this.StatCard('已逾期', this.vm.dashboard.overdueCount.toString(), '#E5CC96', '#D39394')
            this.StatCard('已完成', this.vm.dashboard.doneCount.toString(), '#E5CC96', '#D39394')
          }
          .margin({ top: 10 })

          Column() {
            Row() {
              Column() {
                Text('任务排序')
                  .fontSize(13)
                  .fontColor('#71838F')
                Text(this.vm.sortMode)
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#71838F')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              Button(this.vm.showSortSettings ? '收起' : '设置')
                .height(34)
                .fontSize(13)
                .fontColor('#71838F')
                .backgroundColor('#D6C7B2')
                .borderRadius(8)
                .onClick(() => {
                  this.vm.toggleSortSettings();
                })
            }
            .width('100%')

            if (this.vm.showSortSettings) {
              Row() {
                this.SortButton('截止时间')
                this.SortButton('优先级')
              }
              .margin({ top: 12 })
              Row() {
                this.SortButton('开始时间')
                this.SortButton('创建时间')
              }
              .margin({ top: 8 })
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#E8EADC')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .margin({ top: 16 })
        }
        .padding({ left: 16, right: 8, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .width(380)
      .height('100%')

      Column() {
        this.SectionTitle('全部任务')
        if (this.vm.todos.length === 0) {
          this.EmptyBlock('暂无待完成任务，已完成的任务会进入历史')
        } else {
          Scroll() {
            Column() {
              ForEach(this.vm.todos, (item: TodoTask) => {
                this.TodoCard(item)
              }, (item: TodoTask) => item.id.toString())
            }
          }
          .layoutWeight(1)
        }
      }
      .layoutWeight(1)
      .height('100%')
      .padding({ left: 8, right: 16, top: 16, bottom: 16 })
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  LandscapeScanView() {
    Row() {
      Scroll() {
        Column() {
          Column() {
            Text('课程截图识别')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#71838F')
            Text(this.vm.selectedImage)
              .fontSize(13)
              .fontColor('#71838F')
              .margin({ top: 8 })
            if (this.vm.selectedImageUri.length > 0) {
              Image(this.vm.selectedImageUri)
                .width('100%')
                .height(220)
                .objectFit(ImageFit.Contain)
                .backgroundColor('#E8EADC')
                .borderRadius(8)
                .borderWidth(1)
                .borderColor('#D6C7B2')
                .margin({ top: 12 })
            } else {
              Column() {
                Text('选择一张雨课堂、小雅或课程通知截图')
                  .fontSize(14)
                  .fontColor('#71838F')
              }
              .width('100%')
              .height(160)
              .justifyContent(FlexAlign.Center)
              .backgroundColor('#E8EADC')
              .borderRadius(8)
              .borderWidth(1)
              .borderColor('#D6C7B2')
              .margin({ top: 12 })
            }
            Row() {
              Button('选择本机截图')
                .layoutWeight(1)
                .height(40)
                .fontColor('#E8EADC')
                .backgroundColor('#71838F')
                .borderRadius(8)
                .onClick(() => {
                  this.vm.pickDeviceImage();
                })
              Button(this.vm.recognizing ? '识别中' : '开始本地 OCR')
                .layoutWeight(1)
                .height(40)
                .fontColor('#E8EADC')
                .backgroundColor('#71838F')
                .borderRadius(8)
                .margin({ left: 10 })
                .enabled(!this.vm.recognizing)
                .onClick(() => {
                  this.vm.runOcr();
                })
            }
            .width('100%')
            .margin({ top: 14 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#E8EADC')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')

          Column() {
            this.SectionTitle('识别说明')
            Text('先确认截图已经正确选择，再检查 OCR 原文，最后进入 AI 解析。')
              .fontSize(13)
              .fontColor('#71838F')
              .width('100%')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#E8EADC')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .margin({ top: 12 })
        }
        .padding({ left: 16, right: 8, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .width(400)
      .height('100%')

      Scroll() {
        Column() {
          Text('OCR 原文')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#71838F')
          TextArea({ text: this.vm.ocrText, placeholder: '这里会显示 OCR 文本，也可以手动粘贴课程通知内容' })
            .width('100%')
            .height(250)
            .fontSize(14)
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.vm.ocrText = value;
            })
          Text(this.vm.deepSeekApiKey.trim().length > 0 ? 'DeepSeek: 将调用 deepseek-chat' : 'DeepSeek: 未填写 Key，将使用本地规则')
            .fontSize(12)
            .fontColor(this.vm.deepSeekApiKey.trim().length > 0 ? '#71838F' : '#D39394')
            .width('100%')
            .margin({ top: 8 })
          Button(this.vm.loading ? '解析中' : '下一步：AI 解析')
            .height(44)
            .width('100%')
            .fontColor('#E8EADC')
            .backgroundColor('#71838F')
            .borderRadius(8)
            .margin({ top: 14 })
            .enabled(!this.vm.loading)
            .onClick(() => {
              this.vm.parseOcr();
            })

          Column() {
            this.SectionTitle('当前设置')
            this.InfoLine('选择图片', this.vm.selectedImage)
            this.InfoLine('OCR 状态', this.vm.recognizing ? '识别中' : '空闲')
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#E8EADC')
          .borderRadius(8)
          .borderWidth(1)
          .borderColor('#D6C7B2')
          .margin({ top: 12 })
        }
        .padding({ left: 8, right: 16, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  LandscapeConfirmView() {
    Row() {
      Scroll() {
        Column() {
          this.SectionTitle('解析任务')
          if (this.vm.aiParsedList.length > 0) {
            Column() {
              ForEach(this.vm.aiParsedList, (item: AiParseRecord) => {
                Column() {
                  Text(`${item.parserIndex}. ${this.safeText(item.title)}`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(item.id === this.vm.aiParsed.id ? '#71838F' : '#71838F')
                    .width('100%')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${this.safeText(item.courseName)} · ${this.safeText(item.deadline)}`)
                    .fontSize(12)
                    .fontColor('#71838F')
                    .width('100%')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 4 })
                }
                .width('100%')
                .padding(12)
                .backgroundColor(item.id === this.vm.aiParsed.id ? '#D6C7B2' : '#E8EADC')
                .borderRadius(8)
                .borderWidth(1)
                .borderColor(item.id === this.vm.aiParsed.id ? '#71838F' : '#D6C7B2')
                .margin({ bottom: 8 })
                .onClick(() => {
                  this.vm.selectParsed(item.parserIndex - 1);
                })
              }, (item: AiParseRecord) => item.id.toString())
            }
            .width('100%')

            if (this.vm.aiParsedList.length > 1) {
              Row() {
                Button('上一个')
                  .layoutWeight(1)
                  .height(34)
                  .fontSize(13)
                  .fontColor('#71838F')
                  .backgroundColor('#D6C7B2')
                  .borderRadius(8)
                  .borderWidth(1)
                  .borderColor('#D6C7B2')
                  .enabled(this.vm.aiParsedIndex > 0 && !this.vm.loading)
                  .onClick(() => {
                    this.vm.previousParsed();
                  })
                Button('下一个')
                  .layoutWeight(1)
                  .height(34)
                  .fontSize(13)
                  .fontColor('#71838F')
                  .backgroundColor('#D6C7B2')
                  .borderRadius(8)
                  .borderWidth(1)
                  .borderColor('#D6C7B2')
                  .margin({ left: 10 })
                  .enabled(this.vm.aiParsedIndex < this.vm.aiParsedList.length - 1 && !this.vm.loading)
                  .onClick(() => {
                    this.vm.nextParsed();
                  })
              }
              .width('100%')
              .margin({ top: 4 })
            }
          }
        }
        .padding(16)
        .justifyContent(FlexAlign.Start)
      }
      .width(300)
      .height('100%')

      Scroll() {
        Column() {
          this.SectionTitle(this.vm.draft.sourceType === '手动创建' ? '手动创建 Todo' : '确认 AI 解析结果')
          if (this.vm.confirmFormVersion % 2 === 0) {
            this.ConfirmDraftEditor()
          } else {
            this.ConfirmDraftEditor()
          }
        }
        .padding({ left: 8, right: 8, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .height('100%')

      Scroll() {
        Column() {
          this.ConfirmActions()
          if (this.vm.ocrText.length > 0) {
            this.SectionTitle('OCR 原文')
            Text(this.vm.ocrText)
              .fontSize(13)
              .fontColor('#71838F')
              .width('100%')
              .padding(12)
              .backgroundColor('#E8EADC')
              .borderRadius(8)
              .borderWidth(1)
              .borderColor('#D6C7B2')
          }
        }
        .padding({ left: 8, right: 16, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .width(320)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  LandscapeManualView() {
    Row() {
      Scroll() {
        Column() {
          this.SectionTitle('手动创建 Todo')
          Text('直接填写课程任务信息，保存后会进入数据库。')
            .fontSize(13)
            .fontColor('#71838F')
            .width('100%')
            .margin({ bottom: 4 })

          this.DraftInput('任务标题', 'title', this.vm.draft.title)
          this.DraftInput('课程名称', 'courseName', this.vm.draft.courseName)
          this.DraftInput('截止时间', 'deadline', this.vm.draft.deadline)

          Column() {
            this.SectionTitle('补充说明')
            TextArea({ text: this.vm.draft.description, placeholder: '任务说明' })
              .width('100%')
              .height(180)
              .fontSize(14)
              .backgroundColor('#E8EADC')
              .borderRadius(8)
              .borderWidth(1)
              .borderColor('#D6C7B2')
              .onChange((value: string) => {
                this.vm.setDraftField('description', value);
              })
          }
          .width('100%')
          .margin({ top: 16 })
        }
        .padding({ left: 16, right: 8, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .width('52%')
      .height('100%')

      Scroll() {
        Column() {
          this.SectionTitle('任务属性')

          Row() {
            this.ChoiceButton('作业', this.vm.draft.taskType, 'taskType')
            this.ChoiceButton('实验', this.vm.draft.taskType, 'taskType')
            this.ChoiceButton('报告', this.vm.draft.taskType, 'taskType')
            this.ChoiceButton('测验', this.vm.draft.taskType, 'taskType')
          }

          Row() {
            this.ChoiceButton('小雅', this.vm.draft.platform, 'platform')
            this.ChoiceButton('雨课堂', this.vm.draft.platform, 'platform')
            this.ChoiceButton('飞书', this.vm.draft.platform, 'platform')
            this.ChoiceButton('其他', this.vm.draft.platform, 'platform')
          }
          .margin({ top: 8 })

          Row() {
            this.ChoiceButton('高', this.vm.draft.priority, 'priority')
            this.ChoiceButton('中', this.vm.draft.priority, 'priority')
            this.ChoiceButton('低', this.vm.draft.priority, 'priority')
          }
          .margin({ top: 8 })

          Button(this.vm.loading ? '保存中' : '保存 Todo')
            .height(44)
            .width('100%')
            .fontColor('#E8EADC')
            .backgroundColor('#71838F')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .margin({ top: 18 })
            .enabled(!this.vm.loading)
            .onClick(() => {
              this.vm.saveDraft();
            })
        }
        .padding({ left: 8, right: 16, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  LandscapeTodosView() {
    Row() {
      Scroll() {
        Column() {
          this.SectionTitle('筛选')
          ForEach(['全部', '待完成', '进行中', '已完成', '已逾期'], (item: string) => {
            Button(item)
              .width('100%')
              .height(38)
              .fontSize(12)
              .fontColor(this.vm.filterStatus === item ? '#E8EADC' : '#71838F')
              .backgroundColor(this.vm.filterStatus === item ? '#71838F' : '#D6C7B2')
              .borderRadius(8)
              .borderWidth(1)
              .borderColor(this.vm.filterStatus === item ? '#71838F' : '#D6C7B2')
              .margin({ top: 8 })
              .onClick(async () => {
                await this.vm.changeTodoFilter(item);
              })
          })

          this.SectionTitle('排序')
          Row() {
            this.SortButton('截止时间')
            this.SortButton('优先级')
          }
          Row() {
            this.SortButton('开始时间')
            this.SortButton('创建时间')
          }
          .margin({ top: 8 })
        }
        .padding(16)
        .justifyContent(FlexAlign.Start)
      }
      .width(240)
      .height('100%')

      Scroll() {
        Column() {
          this.SectionTitle('任务列表')
          if (this.vm.todos.length === 0) {
            this.EmptyBlock('暂无任务')
          } else {
            ForEach(this.vm.todos, (item: TodoTask) => {
              this.TodoCard(item)
            }, (item: TodoTask) => item.id.toString())
          }
        }
        .padding({ left: 8, right: 16, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  LandscapeDetailView() {
    Row() {
      Scroll() {
        Column() {
          Button('返回')
            .height(34)
            .fontSize(13)
            .fontColor('#71838F')
            .backgroundColor('#D6C7B2')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 12 })
            .onClick(async () => {
              await this.vm.goBackFromDetail();
            })
          Text(this.displayText(this.vm.currentTodo.title))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#71838F')
          Text(`${this.displayText(this.vm.currentTodo.courseName)} · ${this.displayText(this.vm.currentTodo.taskType)} · ${this.displayPlatform(this.vm.currentTodo.platform)}`)
            .fontSize(14)
            .fontColor('#71838F')
            .margin({ top: 8 })
          this.InfoLine('截止时间', this.vm.currentTodo.deadline)
          this.InfoLine('任务状态', this.vm.currentTodo.status)
          this.InfoLine('优先级', this.vm.currentTodo.priority)
          this.InfoLine('来源', this.vm.currentTodo.sourceType)
          this.InfoLine('创建时间', this.vm.currentTodo.createdAt)
          Text(this.displayText(this.vm.currentTodo.description))
            .fontSize(14)
            .fontColor('#71838F')
            .width('100%')
            .padding(14)
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .margin({ top: 12 })
        }
        .padding(16)
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .height('100%')

      Scroll() {
        Column() {
          this.SectionTitle('任务操作')
          Button('删除任务')
            .height(40)
            .width('100%')
            .fontColor('#D39394')
            .backgroundColor('#E5CC96')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .margin({ top: 16 })
            .onClick(() => {
              this.vm.removeCurrentTodo();
            })
        }
        .padding({ left: 8, right: 16, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .width(270)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  LandscapeHistoryView() {
    Row() {
      Scroll() {
        Column() {
          this.SectionTitle('已完成任务')
          if (this.vm.completedTodos.length === 0) {
            this.EmptyBlock('还没有已完成任务')
          } else {
            ForEach(this.vm.completedTodos, (item: TodoTask) => {
              this.CompletedTaskCard(item)
            }, (item: TodoTask) => item.id.toString())
          }
        }
        .padding(16)
        .justifyContent(FlexAlign.Start)
      }
      .width(360)
      .height('100%')

      Scroll() {
        Column() {
          if (this.vm.selectedCompletedTodo.id > 0) {
            if (this.vm.selectedCompletedDetailVersion % 2 === 0) {
              this.CompletedHistoryDetail(this.vm.selectedCompletedTodo)
            } else {
              this.CompletedHistoryDetail(this.vm.selectedCompletedTodo)
            }
          } else {
            this.EmptyBlock('请选择一条已完成任务查看详情')
          }
        }
        .padding({ left: 8, right: 16, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  LandscapeMineView() {
    Row() {
      Scroll() {
        Column() {
          this.SectionTitle('账户概览')
          this.InfoLine('用户名', this.vm.user.username)
          this.InfoLine('任务总数', this.vm.dashboard.totalCount.toString())
          this.InfoLine('已完成', this.vm.completedTodos.length.toString())
          this.InfoLine('未完成', this.vm.todos.length.toString())
          this.InfoLine('DeepSeek API', this.vm.deepSeekApiKey.length > 0 ? '已填写，将用于下一次 AI 解析' : '未填写，后端会使用本地规则解析')

          this.SectionTitle('DeepSeek 设置')
          TextInput({ text: this.vm.deepSeekApiKey, placeholder: '粘贴 DeepSeek API Key' })
            .height(42)
            .width('100%')
            .backgroundColor('#E8EADC')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .type(InputType.Password)
            .onChange((value: string) => {
              this.vm.deepSeekApiKey = value;
            })
          Text('Key 只会随本次解析请求发送给后端，不写进应用源码。')
            .fontSize(12)
            .fontColor('#71838F')
            .width('100%')
            .margin({ top: 8 })
        }
        .padding({ left: 16, right: 8, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .width('44%')
      .height('100%')

      Scroll() {
        Column() {
          this.SectionTitle('数据')
          Button(this.vm.clearConfirmArmed ? '再次点击确认清除' : '清除本人所有数据')
            .height(42)
            .width('100%')
            .fontColor('#D39394')
            .backgroundColor('#E5CC96')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .enabled(!this.vm.loading)
            .onClick(async () => {
              await this.vm.clearMyData();
            })
          Text('只删除当前账号的任务、已完成归档、AI 记录和课程数据，不删除账号。')
            .fontSize(12)
            .fontColor('#71838F')
            .width('100%')
            .margin({ top: 8 })

          Button('退出登录')
            .height(42)
            .width('100%')
            .fontColor('#D39394')
            .backgroundColor('#E5CC96')
            .borderRadius(8)
            .borderWidth(1)
            .borderColor('#D6C7B2')
            .margin({ top: 18 })
            .onClick(() => {
              this.vm.logout();
            })
        }
        .padding({ left: 8, right: 16, top: 16, bottom: 16 })
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor('#71838F')
      .width('100%')
      .margin({ top: 16, bottom: 10 })
  }

  @Builder
  EmptyBlock(text: string) {
    Column() {
      Text(text)
        .fontSize(15)
        .fontColor('#71838F')
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#E8EADC')
    .borderRadius(8)
    .borderWidth(1)
    .borderColor('#D6C7B2')
  }

  @Builder
  InfoLine(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#71838F')
        .width(82)
      Text(this.displayText(value))
        .fontSize(14)
        .fontColor('#71838F')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .borderColor('#D6C7B2')
    .borderWidth({ bottom: 1 })
  }

  @Builder
  NavBar() {
    Row() {
      this.NavButton('首页', 'home')
      this.NavButton('识别', 'scan')
      this.NavButton('手动', 'manual')
      this.NavButton('我的', 'mine')
    }
    .width('100%')
    .height(58)
    .padding({ left: 8, right: 8 })
    .backgroundColor('#E8EADC')
  }

  @Builder
  NavButton(label: string, target: string) {
    Button(label)
      .layoutWeight(1)
      .height(38)
      .fontSize(13)
      .fontColor(this.vm.screen === target ? '#E8EADC' : '#71838F')
      .backgroundColor(this.vm.screen === target ? '#71838F' : '#E8EADC')
      .borderRadius(8)
      .borderWidth(1)
      .borderColor(this.vm.screen === target ? '#71838F' : '#D6C7B2')
      .margin({ left: 3, right: 3 })
      .onClick(async () => {
        await this.vm.navigateTo(target);
      })
  }

  build() {
    Column() {
      if (this.vm.screen === 'auth') {
        this.AuthView()
      } else if (this.isLandscape()) {
        this.LandscapeShell()
      } else {
        this.PortraitShell()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E8EADC')
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.updateViewport(newValue);
    })
  }
}
