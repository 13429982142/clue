-- 商务线索挖掘与转化智能体 (PRD v1.0)
-- MySQL 8.0 物理结构表图
CREATE DATABASE IF NOT EXISTS lead_conversion_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lead_conversion_db;

-- 1. 线索总表 (Leads Table)
CREATE TABLE IF NOT EXISTS `tbl_leads` (
  `id` VARCHAR(64) NOT NULL COMMENT 'UUID/唯一标识',
  `title` VARCHAR(255) NOT NULL COMMENT '项目/公告名称',
  `company` VARCHAR(255) NOT NULL COMMENT '招标单位/业主全名',
  `publish_date` DATE NOT NULL COMMENT '公开招标/发现发布日期',
  `region` TEXT NOT NULL COMMENT '行政区域 (如: 广东省广州市)',
  `industry` VARCHAR(100) DEFAULT NULL COMMENT '细分行业',
  `category` VARCHAR(100) DEFAULT NULL COMMENT '品类分类',
  `source_db` VARCHAR(150) DEFAULT NULL COMMENT '来源网络名称',
  `requirements` TEXT DEFAULT NULL COMMENT '细节说明与痛点诉求',
  `notes` TEXT DEFAULT NULL COMMENT '额外标注/备注',
  
  -- 评分分值
  `budget_score` INT DEFAULT 50 COMMENT '项目预算分 (0-100)',
  `match_score` INT DEFAULT 50 COMMENT '需求匹配度分 (0-100)',
  `stage_score` INT DEFAULT 50 COMMENT '项目阶段分 (0-100)',
  `qualification_score` INT DEFAULT 50 COMMENT '客户资质分 (0-100)',
  `region_score` INT DEFAULT 50 COMMENT '地域匹配分 (0-100)',
  `total_score` DECIMAL(5,2) DEFAULT NULL COMMENT '加权计算后的总评分',
  `grade` CHAR(1) DEFAULT 'B' COMMENT '线索分级 (A/B/C)',
  
  -- 额外拓展字段
  `deadline_date` DATE DEFAULT NULL COMMENT '截止时间',
  `budget_amount` DECIMAL(12,2) DEFAULT NULL COMMENT '项目预算金额(万)',
  `is_urgent` BOOLEAN DEFAULT FALSE COMMENT '是否加急(高意向)',
  `labels` TEXT DEFAULT NULL COMMENT '打标(改造类型等JSON)',
  `crawl_time` DATETIME DEFAULT NULL COMMENT '抓取时间',
  
  -- 跟进状态与销售流转
  `status` VARCHAR(30) DEFAULT '待分级' COMMENT '待分级/待分配/跟进中/已转化/已无效/已流失',
  `follow_up_person` VARCHAR(100) DEFAULT NULL COMMENT '主责销售负责人',
  `contact_name` VARCHAR(100) DEFAULT NULL COMMENT '联系人姓名',
  `contact_phone` VARCHAR(30) DEFAULT NULL COMMENT '联系人电话',
  
  -- AI 生成的智库状态
  `pre_research_report` MEDIUMTEXT DEFAULT NULL COMMENT 'AI 生成的预调研研判报告',
  `research_date` DATE DEFAULT NULL COMMENT '研判时间',
  `proposal_draft` MEDIUMTEXT DEFAULT NULL COMMENT 'AI 生成的项目商务标书方案初稿',
  `proposal_price` DECIMAL(12,2) DEFAULT NULL COMMENT '估算金额/方案建议总价',
  `competitor_analysis` MEDIUMTEXT DEFAULT NULL COMMENT 'AI多维竞合矩阵破局报告',
  `created_by` VARCHAR(100) DEFAULT NULL COMMENT '创建该线索的用户账号',
  `return_reason` TEXT DEFAULT NULL COMMENT '逆向退回原因',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 打分公式规则配置表 (Scoring Weights Config)
CREATE TABLE IF NOT EXISTS `tbl_scoring_rules` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `budget_weight` INT DEFAULT 20 COMMENT '项目预算权重占比%',
  `match_weight` INT DEFAULT 30 COMMENT '需求匹配度权重占比%',
  `stage_weight` INT DEFAULT 25 COMMENT '项目阶段权重占比%',
  `qualification_weight` INT DEFAULT 15 COMMENT '客户资质权重占比%',
  `region_weight` INT DEFAULT 10 COMMENT '地域匹配权重占比%',
  `warning_threshold` INT DEFAULT 80 COMMENT '预警高危线索线',
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 系统操作与审计日志 (Audit Logger)
CREATE TABLE IF NOT EXISTS `tbl_audit_logs` (
  `id` VARCHAR(64) NOT NULL,
  `timestamp` DATETIME NOT NULL COMMENT '记录发生时间',
  `operator` VARCHAR(100) NOT NULL COMMENT '操作账号姓名',
  `role` VARCHAR(50) NOT NULL COMMENT '操作角色级别',
  `action_type` VARCHAR(100) NOT NULL COMMENT '操作类型(录入/更新/AI研判)',
  `target_id` VARCHAR(64) DEFAULT NULL COMMENT '关联线索ID',
  `details` TEXT COMMENT '行为动作日志描述详情',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 竞争对手档案库 (Competitors Repository)
CREATE TABLE IF NOT EXISTS `tbl_competitors` (
  `id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(255) NOT NULL COMMENT '竞品名称',
  `strengths` TEXT COMMENT '优势分析(JSON 数组或逗号分隔文本)',
  `weaknesses` TEXT COMMENT '劣势分析(JSON 数组或逗号分隔文本)',
  `pricing_range` VARCHAR(100) DEFAULT NULL COMMENT '报价水平',
  `win_rate` INT DEFAULT 50 COMMENT '历史中标胜率(%)',
  `main_business` TEXT DEFAULT NULL COMMENT '主营业务',
  `tech_route` TEXT DEFAULT NULL COMMENT '技术路线',
  `typical_cases` TEXT DEFAULT NULL COMMENT '典型案例(纯文本或 JSON 文本)',
  `info_source` TEXT DEFAULT NULL COMMENT '信息来源(来源链接/出处)',
  `monitoring_intel` TEXT DEFAULT NULL COMMENT '最新监测动态 JSON(新品/中标/技术/报价/案例)',
  `updated_at` DATETIME DEFAULT NULL COMMENT '资料更新时间',
  `status` VARCHAR(20) DEFAULT 'active' COMMENT '状态 active=有效 / inactive=失效(软失效)',
  `priority` VARCHAR(10) DEFAULT 'normal' COMMENT '监测优先级 key=重点关注(每3天) / normal=普通(每周)',
  `last_enriched_at` DATETIME DEFAULT NULL COMMENT '最近一次 AI 动态检索时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4b. 竞品动态更新记录 (Competitor Update Logs)
-- 每次 AI(DeepSeek) 全网检索补全竞品库时留痕，可追溯变更内容
CREATE TABLE IF NOT EXISTS `tbl_competitor_updates` (
  `id` VARCHAR(64) NOT NULL,
  `competitor_id` VARCHAR(64) NOT NULL COMMENT '关联竞品ID',
  `changed_fields` TEXT DEFAULT NULL COMMENT '本次变更的基础字段摘要 (JSON)',
  `intel_payload` TEXT DEFAULT NULL COMMENT '五类监测动态完整内容 (JSON)',
  `source` TEXT DEFAULT NULL COMMENT '信息来源(DeepSeek/检索出处)',
  `created_at` DATETIME DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_competitor_update` (`competitor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 标书方案核心模板库
CREATE TABLE IF NOT EXISTS `tbl_templates` (
  `id` VARCHAR(64) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `category` VARCHAR(100) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `content` MEDIUMTEXT COMMENT '模板大纲 Markdown 格式内容',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. 预调研档案版本库 (Pre-Research Reports Archive)
-- 每次生成保留为一个历史版本，绑定线索ID，可追溯
CREATE TABLE IF NOT EXISTS `tbl_research_reports` (
  `id` VARCHAR(64) NOT NULL COMMENT 'UUID/唯一标识',
  `lead_id` VARCHAR(64) NOT NULL COMMENT '关联线索ID',
  `version` INT DEFAULT 1 COMMENT '版本号 (同线索递增)',
  `created_at` DATETIME DEFAULT NULL COMMENT '生成时间',
  `operator` VARCHAR(100) DEFAULT NULL COMMENT '发起调研的操作人',
  `engine` VARCHAR(20) DEFAULT NULL COMMENT '生成引擎 rule=规则引擎 / llm=大模型',
  `completeness` INT DEFAULT 0 COMMENT '信息完整度 0-100',
  `aggregated_info` MEDIUMTEXT DEFAULT NULL COMMENT '结构化调研原始信息集 (JSON, 含来源)',
  `sources` MEDIUMTEXT DEFAULT NULL COMMENT '来源链接列表 (JSON: [{label,url}])',
  `missing_items` TEXT DEFAULT NULL COMMENT '缺失/待确认项清单 (JSON list)',
  `report_content` MEDIUMTEXT DEFAULT NULL COMMENT '痛点分析报告全文',
  `is_sufficient` TINYINT DEFAULT 1 COMMENT '公开信息是否充足 0=不足/1=充足',
  PRIMARY KEY (`id`),
  KEY `idx_research_lead` (`lead_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7b. 线索活动/跟进记录表 (Lead Activity Log)
CREATE TABLE IF NOT EXISTS `tbl_lead_activities` (
  `id` VARCHAR(64) NOT NULL COMMENT 'UUID',
  `lead_id` VARCHAR(64) NOT NULL COMMENT '关联线索ID',
  `activity_type` VARCHAR(50) DEFAULT 'comment' COMMENT '活动类型 comment/status_change/note/system',
  `content` TEXT COMMENT '活动内容/跟进备注',
  `operator` VARCHAR(100) DEFAULT NULL COMMENT '操作人',
  `created_at` DATETIME DEFAULT NULL COMMENT '记录时间',
  PRIMARY KEY (`id`),
  KEY `idx_activity_lead` (`lead_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7c. 数据源健康监控表 (Source Health)
CREATE TABLE IF NOT EXISTS `tbl_source_health` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `source` VARCHAR(255) NOT NULL COMMENT '数据源名称或URL',
  `status` VARCHAR(20) DEFAULT 'healthy' COMMENT '健康状态 healthy/degraded/abnormal',
  `consecutive_failures` INT DEFAULT 0 COMMENT '连续失败次数',
  `total_fetches` INT DEFAULT 0 COMMENT '总抓取次数',
  `total_failures` INT DEFAULT 0 COMMENT '总失败次数',
  `structure_change_detected` INT DEFAULT 0 COMMENT '页面结构变更标记 0/1',
  `last_success_at` DATETIME DEFAULT NULL COMMENT '最后成功时间',
  `last_failure_at` DATETIME DEFAULT NULL COMMENT '最后失败时间',
  `last_error_message` TEXT DEFAULT NULL COMMENT '最后错误信息',
  `created_at` DATETIME DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_source_health_source` (`source`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7d. 客户档案表 (Customer Profiles)
CREATE TABLE IF NOT EXISTS `tbl_customer_profiles` (
  `id` VARCHAR(64) NOT NULL COMMENT 'UUID',
  `lead_id` VARCHAR(64) NOT NULL COMMENT '来源线索ID',
  `company` VARCHAR(255) NOT NULL COMMENT '公司名称',
  `industry` VARCHAR(100) DEFAULT NULL COMMENT '行业',
  `region` VARCHAR(100) DEFAULT NULL COMMENT '地区',
  `contact_name` VARCHAR(100) DEFAULT NULL COMMENT '联系人',
  `contact_phone` VARCHAR(30) DEFAULT NULL COMMENT '联系电话',
  `source_db` VARCHAR(150) DEFAULT NULL COMMENT '来源',
  `budget_amount` DECIMAL(12,2) DEFAULT NULL COMMENT '预算金额(万)',
  `requirements` TEXT DEFAULT NULL COMMENT '需求描述',
  `converted_by` VARCHAR(100) DEFAULT NULL COMMENT '转化人',
  `converted_at` DATETIME DEFAULT NULL COMMENT '转化时间',
  `created_at` DATETIME DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_customer_lead` (`lead_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7e. 项目台账表 (Project Ledgers)
CREATE TABLE IF NOT EXISTS `tbl_project_ledgers` (
  `id` VARCHAR(64) NOT NULL COMMENT 'UUID',
  `lead_id` VARCHAR(64) NOT NULL COMMENT '来源线索ID',
  `customer_profile_id` VARCHAR(64) NOT NULL COMMENT '关联客户档案ID',
  `project_name` VARCHAR(255) NOT NULL COMMENT '项目名称',
  `project_amount` DECIMAL(12,2) DEFAULT NULL COMMENT '项目金额(万)',
  `project_stage` VARCHAR(50) DEFAULT '立项' COMMENT '项目阶段',
  `region` VARCHAR(100) DEFAULT NULL COMMENT '地区',
  `created_by` VARCHAR(100) DEFAULT NULL COMMENT '创建人',
  `created_at` DATETIME DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_project_lead` (`lead_id`),
  KEY `idx_project_customer` (`customer_profile_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7f. 推送规则配置表 (Push Rules)
CREATE TABLE IF NOT EXISTS `tbl_push_rules` (
  `id` VARCHAR(64) NOT NULL COMMENT 'UUID',
  `rule_name` VARCHAR(100) DEFAULT '默认推送规则' COMMENT '规则名称',
  `status` VARCHAR(20) DEFAULT 'active' COMMENT '状态 active/inactive',
  `high_intent_mode` VARCHAR(50) DEFAULT 'realtime' COMMENT '高意向推送模式 realtime/batch',
  `medium_intent_schedule_hour` INT DEFAULT 18 COMMENT '中意向汇总推送时',
  `medium_intent_schedule_minute` INT DEFAULT 0 COMMENT '中意向汇总推送分',
  `low_intent_silent` INT DEFAULT 1 COMMENT '低意向是否静默 1=静默',
  `targets` TEXT DEFAULT NULL COMMENT '推送目标 JSON',
  `created_at` DATETIME DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7g. 推送记录表 (Push Records)
CREATE TABLE IF NOT EXISTS `tbl_push_records` (
  `id` VARCHAR(64) NOT NULL COMMENT 'UUID',
  `title` VARCHAR(255) NOT NULL COMMENT '推送标题',
  `receiver_name` VARCHAR(100) DEFAULT NULL COMMENT '接收人',
  `channels` VARCHAR(100) DEFAULT NULL COMMENT '推送渠道',
  `status` VARCHAR(20) DEFAULT 'pending' COMMENT '状态 pending/retrying/sent/failed',
  `retry_count` INT DEFAULT 0 COMMENT '已重试次数',
  `max_retry` INT DEFAULT 3 COMMENT '最大重试次数',
  `error_message` TEXT DEFAULT NULL COMMENT '错误信息',
  `content` TEXT DEFAULT NULL COMMENT '推送内容',
  `created_at` DATETIME DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. 网监抓取规则配置库 (Web Monitoring/Search Config)
CREATE TABLE IF NOT EXISTS `tbl_search_config` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `rule_name` VARCHAR(100) DEFAULT '默认规则' COMMENT '规则名称',
  `status` VARCHAR(20) DEFAULT 'active' COMMENT '状态',
  `monitor_sources` TEXT COMMENT '监控数据来源 (以半角逗号分隔)',
  `keywords` TEXT COMMENT '监控关键字词池 (以半角逗号分隔)',
  `exclude_keywords` TEXT COMMENT '排除负向词/黑名单字词 (以半角逗号分隔)',
  `regions` TEXT COMMENT '数据抓取目标区域 (以半角逗号分隔)',
  `industries` TEXT COMMENT '数据抓取目标行业 (以半角逗号分隔)',
  `categories` TEXT COMMENT '数据抓取目标分类 (以半角逗号分隔)',
  `frequency` VARCHAR(100) DEFAULT '每天早上8:00实时' COMMENT '自动巡环发现频率',
  `budget_min` INT DEFAULT 0 COMMENT '预算下限',
  `budget_max` INT DEFAULT 2000 COMMENT '预算上限',
  `purchase_types` TEXT COMMENT '采购主体类别 (以半角逗号分隔)',
  `time_range` VARCHAR(100) DEFAULT '不限' COMMENT '监控发布时间范围',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 初始化配置初始种子
INSERT INTO `tbl_scoring_rules` (`budget_weight`, `match_weight`, `stage_weight`, `qualification_weight`, `region_weight`, `warning_threshold`)
VALUES (20, 30, 25, 15, 10, 80);

-- 初始化网监默认规则种子
INSERT INTO `tbl_search_config` (`monitor_sources`, `keywords`, `exclude_keywords`, `regions`, `industries`, `categories`, `frequency`, `budget_min`, `budget_max`, `purchase_types`, `time_range`)
VALUES ('全国公共资源交易平台,地方环保局公告栏', '机电节能改造,空调智慧控制', '土建,管网,纯设备采购', '广东省', '全部', '全部', '每天早上8:00实时', 0, 2000, '国企,事业单位,民企', '不限');

-- 8. 系统用户与权限表 (Users Table)
CREATE TABLE `tbl_users` (
  `id` int(200) NOT NULL AUTO_INCREMENT COMMENT 'UUID/唯一标识',
  `username` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '登录账号/唯一标识',
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '哈希加密后的密码',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '真实姓名/审计显示',
  `role` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '角色权限(超级管理员/商务负责人/商务专员/查看角色)',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_username` (`username`) BLOCK_SIZE 16384 LOCAL
) ORGANIZATION INDEX AUTO_INCREMENT = 5 AUTO_INCREMENT_MODE = 'ORDER' DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci ROW_FORMAT = DYNAMIC COMPRESSION = 'zstd_1.3.8' REPLICA_NUM = 1 BLOCK_SIZE = 16384 USE_BLOOM_FILTER = FALSE ENABLE_MACRO_BLOCK_BLOOM_FILTER = FALSE TABLET_SIZE = 134217728 PCTFREE = 0;

-- 初始化系统用户种子数据 (密码均为用户名+123，使用 SHA-256 加密)
INSERT INTO `tbl_users` (`username`, `password`, `name`, `role`, `created_at`)
VALUES 
('admin', SHA2('admin123', 256), '超级管理员陈工', '超级管理员', NOW()),
('manager', SHA2('manager123', 256), '市场组长刘经理', '商务负责人', NOW()),
('sales', SHA2('sales123', 256), '前端突破专员王小二', '商务专员', NOW()),
('visitor', SHA2('visitor123', 256), '查看角色访客', '查看角色', NOW());

-- 9. 用户收藏表 (User Favorites)
CREATE TABLE IF NOT EXISTS `tbl_user_favorites` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `user_id` INT NOT NULL COMMENT '用户ID',
  `lead_id` VARCHAR(64) NOT NULL COMMENT '线索ID',
  PRIMARY KEY (`id`),
  KEY `idx_fav_user` (`user_id`),
  KEY `idx_fav_lead` (`lead_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
