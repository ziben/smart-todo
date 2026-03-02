import 'package:flutter_test/flutter_test.dart';
import 'package:smart_todo/services/nlp_service.dart';
import 'package:smart_todo/domain/models/task_model.dart';

void main() {
  late NlpServiceImpl nlpService;

  setUp(() {
    nlpService = NlpServiceImpl();
  });

  group('NlpService 解析功能测试', () {
    test('解析简单任务标题', () {
      final result = nlpService.parse('完成代码评审');
      expect(result.title, '完成代码评审');
      expect(result.priority, TaskPriority.none);
      expect(result.dueDate, isNull);
    });

    test('解析今天任务', () {
      final result = nlpService.parse('今天 提交代码');
      expect(result.title, '提交代码');
      expect(result.dueDate, isNotNull);
      expect(result.dueDate!.day, DateTime.now().day);
    });

    test('解析明天任务', () {
      final result = nlpService.parse('明天 完成测试');
      expect(result.title, '完成测试');
      expect(result.dueDate, isNotNull);
      expect(result.dueDate!.day, DateTime.now().add(const Duration(days: 1)).day);
    });

    test('解析后天任务', () {
      final result = nlpService.parse('后天 开会');
      expect(result.title, '开会');
      expect(result.dueDate, isNotNull);
      expect(result.dueDate!.day, DateTime.now().add(const Duration(days: 2)).day);
    });

    test('解析具体时间', () {
      final result = nlpService.parse('下午3点 召开会议');
      expect(result.title, '召开会议');
      expect(result.dueTime, isNotNull);
      expect(result.dueTime!.hour, 15);
    });

    test('解析 P0 紧急任务', () {
      final result = nlpService.parse('P0 紧急修复bug');
      expect(result.title, '紧急修复bug');
      expect(result.priority, TaskPriority.urgent);
    });

    test('解析 P1 高优先级', () {
      final result = nlpService.parse('P1 完成设计方案');
      expect(result.title, '完成设计方案');
      expect(result.priority, TaskPriority.high);
    });

    test('解析中文优先级关键词', () {
      expect(nlpService.parse('紧急 任务').priority, TaskPriority.urgent);
      expect(nlpService.parse('重要 任务').priority, TaskPriority.high);
      expect(nlpService.parse('普通 任务').priority, TaskPriority.medium);
    });

    test('解析标签', () {
      final result = nlpService.parse('完成任务 #工作 #紧急');
      expect(result.title, '完成任务');
      expect(result.tags, contains('工作'));
      expect(result.tags, contains('紧急'));
    });

    test('解析预计时长', () {
      final result = nlpService.parse('写代码 2小时');
      expect(result.title, '写代码');
      expect(result.estimatedDuration, 120);
    });

    test('解析分钟预计时长', () {
      final result = nlpService.parse('打电话 30分钟');
      expect(result.title, '打电话');
      expect(result.estimatedDuration, 30);
    });

    test('解析完整任务 - 所有信息', () {
      final result = nlpService.parse('P1 明天上午9点 完成项目汇报 #工作 1小时');
      expect(result.priority, TaskPriority.high);
      expect(result.estimatedDuration, 60);
      expect(result.tags, contains('工作'));
    });

    test('解析下周任务', () {
      final result = nlpService.parse('下周一 项目启动');
      expect(result.title, '项目启动');
      expect(result.dueDate, isNotNull);
    });

    test('解析早上时间', () {
      final result = nlpService.parse('早上8点 开会');
      expect(result.dueTime, isNotNull);
      expect(result.dueTime!.hour, 8);
    });

    test('解析晚上时间', () {
      final result = nlpService.parse('晚上7点 锻炼');
      expect(result.dueTime, isNotNull);
      expect(result.dueTime!.hour, 19);
    });

    test('解析凌晨/深夜', () {
      expect(nlpService.parse('深夜 完成任务').dueTime?.hour, 23);
    });
  });

  group('NlpService 关键词提取', () {
    test('提取日期关键词', () {
      final keywords = nlpService.extractKeywords('今天明天周一开会');
      expect(keywords, contains('今天'));
      expect(keywords, contains('明天'));
    });

    test('提取时间关键词', () {
      final keywords = nlpService.extractKeywords('下午3点30分 开会');
      expect(keywords.any((k) => k.contains('3点') || k.contains('3:30')), isTrue);
    });

    test('提取标签关键词', () {
      final keywords = nlpService.extractKeywords('#工作 #生活 测试');
      expect(keywords.any((k) => k.contains('#工作')), isTrue);
    });
  });

  group('NlpService 语言检测', () {
    test('检测中文', () {
      expect(nlpService.detectLanguage('这是一个中文测试'), 'zh');
    });

    test('检测英文', () {
      expect(nlpService.detectLanguage('This is English'), 'en');
    });
  });

  group('NlpService 验证', () {
    test('验证有效解析结果', () {
      final result = nlpService.parse('完成任务');
      expect(nlpService.validate(result), isTrue);
    });

    test('验证空标题', () {
      final result = nlpService.parse('');
      expect(nlpService.validate(result), isFalse);
    });
  });

  group('NlpService 批量解析', () {
    test('批量解析多个任务', () {
      final inputs = ['任务1', '任务2', '任务3'];
      final results = nlpService.parseBatch(inputs);
      expect(results.length, 3);
      expect(results[0].title, '任务1');
      expect(results[1].title, '任务2');
      expect(results[2].title, '任务3');
    });
  });
}