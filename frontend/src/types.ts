/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export interface Lead {
  id: string;
  title: string;
  company: string;
  publishDate: string;
  region: string;
  industry: string;
  category: string;
  sourceDb: string;
  requirements: string;
  notes?: string;
  
  // 评分参数
  budgetScore: number;       // 预算匹配分 (20%)
  matchScore: number;        // 需求匹配度 (30%)
  qualificationScore: number; // 客户资质 (25%)
  stageScore: number;        // 项目阶段分 (15%)
  regionScore: number;       // 地域匹配分 (10%)
  totalScore: number;        // 加权总分
  grade: 'A' | 'B' | 'C';    // A级: >=80, B级: 50-79, C级: <50
  
  // PRD新增字段
  deadlineDate?: string;     // 截止时间
  budgetAmount?: number;     // 项目预算金额(万)
  isUrgent?: boolean;        // 是否加急(高意向)
  labels?: string;           // 打标(改造类型等JSON)
  isFavorite?: boolean;      // 是否收藏
  crawlTime?: string;        // 抓取时间
  source?: string;           // 线索来源: crawler / import / manual
  createdAt?: string;        // 创建时间
  purchaseType?: string;     // 采购单位类型(国企/事业单位/民企)
  missingInfoTags?: string[];    // 信息不全标签(缺失字段名)
  informationComplete?: boolean; // 信息是否完整
  assignedTo?: string;       // 按地区/行业分配的跟进人
  importBatchId?: string;    // Excel导入批次ID
  sourceUrl?: string;        // 公告原文链接

  // 分类标签（从原始抓取数据归一化）
  renovationTags?: string[];
  projectStage?: '招标' | '意向征集' | '规划';

  // 跟进信息
  status: '待分级' | '待分配' | '跟进中' | '已转化' | '已无效' | '已流失';
  followUpPerson?: string;
  contactName?: string;
  contactPhone?: string;
  returnReason?: string;
  
  // 关联报告（缓存或生成）
  preResearchReport?: string;
  researchDate?: string;
  proposalDraft?: string;
  proposalDate?: string;
  proposalPrice?: number;
  competitorAnalysis?: string;
  competitorDate?: string;
  createdBy?: string;
}

export interface ResearchSource {
  label: string;
  url: string;
}

export interface ResearchReport {
  id: string;
  leadId: string;
  version: number;
  createdAt: string;
  operator?: string;
  engine: 'rule' | 'llm' | string;
  completeness: number;
  aggregatedInfo: Record<string, any>;
  sources: ResearchSource[];
  missingItems: string[];
  reportContent: string;
  isSufficient: boolean;
}

export interface ScoringRule {
  budgetWeight: number;     // 默认20
  matchWeight: number;       // 默认30
  qualificationWeight: number; // 默认25
  stageWeight: number;       // 默认15
  regionWeight: number;      // 默认10
  warningThreshold: number;  // 默认80
}

// 监测规则状态: active=生效 / paused=暂停 / draft=草稿
export type RuleStatus = 'active' | 'paused' | 'draft';

// 关键词优先级: high=高优先级(每4小时增量) / normal=普通(每日1次)
export type KeywordPriority = 'high' | 'normal';

// 监测规则(支持多套并行)
export interface MonitorRule {
  id: string;
  ruleName: string;                  // 业务线规则名称
  status: RuleStatus;                 // 生效状态
  businessLine?: string;              // 业务线标识
  monitorSources: string[];
  keywords: string[];
  excludeKeywords: string[];
  highPriorityKeywords?: string[];    // 高优先级关键词(每4小时增量)
  regions: string[];
  industries: string[];
  categories: string[];
  frequency: string;
  budgetMin?: number;
  budgetMax?: number;
  purchaseTypes?: string[];
  publishDateFrom?: string;           // 项目发布时间范围-起 YYYY-MM-DD
  publishDateTo?: string;             // 项目发布时间范围-止 YYYY-MM-DD
  createdAt?: string;
  updatedAt?: string;
  createdBy?: string;
}

// 数据源健康状态
export type SourceHealthStatus = 'healthy' | 'degraded' | 'abnormal';

export interface SourceHealth {
  source: string;
  status: SourceHealthStatus;
  consecutiveFailures: number;        // 连续失败次数
  lastSuccessAt?: string;
  lastFailureAt?: string;
  lastErrorMessage?: string;
  totalFetches: number;
  totalFailures: number;
  structureChangeDetected?: boolean;  // 页面结构变更标记
}

// 推送渠道
export type PushChannel = 'system' | 'wecom' | 'email';

// 推送状态
export type PushStatus = 'pending' | 'sent' | 'failed' | 'retrying';

export interface PushTarget {
  receiverName: string;               // 接收人姓名
  receiverRole?: string;
  channels: PushChannel[];            // 推送渠道
  wecomUserId?: string;               // 企业微信UserId
}

export interface PushRecord {
  id: string;
  leadId?: string;
  leadIds?: string[];                 // 汇总推送时多个线索
  receiverName: string;
  channels: PushChannel[];
  title: string;
  content: string;
  status: PushStatus;
  retryCount: number;
  maxRetry: number;                   // 默认2次
  scheduledAt?: string;               // 定时推送时间(如每日18:00汇总)
  sentAt?: string;
  lastError?: string;
  createdAt: string;
}

// 推送规则配置
export interface PushRule {
  id: string;
  ruleName: string;
  status: 'active' | 'paused';
  // 高意向: 实时推送; 中意向: 每日18点汇总; 低意向: 不主动推送
  highIntentMode: 'realtime';         // 高意向实时
  mediumIntentScheduleHour: number;   // 中意向汇总小时(默认18)
  mediumIntentScheduleMinute: number; // 默认0
  lowIntentSilent: boolean;
  // 按地区/行业分配
  regionAssignees?: Record<string, string>;  // 地区 -> 跟进人
  industryAssignees?: Record<string, string>; // 行业 -> 跟进人
  targets: PushTarget[];
}

// 线索活动记录(跟进记录/状态变更留痕)
export interface LeadActivity {
  id: string;
  leadId: string;
  activityType: 'comment' | 'status_change' | 'note' | 'system' | 'call' | 'meeting' | 'email';
  content: string;
  operator: string;
  operatorRole?: string;
  fromStatus?: string;
  toStatus?: string;
  createdAt: string;
}

// 客户档案(线索转化生成)
export interface CustomerProfile {
  id: string;
  leadId: string;                     // 来源线索
  company: string;
  contactName?: string;
  contactPhone?: string;
  region?: string;
  industry?: string;
  convertedAt: string;
  convertedBy: string;
  projectBookId?: string;             // 关联项目台账
}

// 项目台账
export interface ProjectLedger {
  id: string;
  leadId: string;
  customerId: string;
  projectName: string;
  budgetAmount?: number;
  status: '立项' | '跟进中' | '已签约' | '已交付' | '已回款';
  createdAt: string;
  createdBy: string;
}

// Excel 导入结果
export interface ImportResult {
  totalRows: number;
  imported: number;
  duplicated: number;
  duplicates: Array<{ row: number; title: string; company: string; action: 'skipped' | 'overwritten' }>;
  errors: Array<{ row: number; field?: string; reason: string }>;
  importedLeads: Lead[];
}

// 多维度筛选条件
export interface LeadFilterCriteria {
  grades?: Array<'A' | 'B' | 'C'>;
  statuses?: Lead['status'][];
  projectStages?: Array<'招标' | '意向征集' | '规划'>;
  renovationTags?: string[];
  regions?: string[];
  industries?: string[];
  budgetMin?: number;
  budgetMax?: number;
  publishDateFrom?: string;
  publishDateTo?: string;
  sources?: string[];
  searchKeyword?: string;
  isUrgent?: boolean;
  followUpPerson?: string;
}

export interface AuditLog {
  id: string;
  timestamp: string;
  operator: string;
  role: string;
  actionType: string;
  targetId?: string;
  targetTitle?: string;
  details: string;
}

export interface CompetitorIntelItem {
  title?: string;
  summary?: string;
  source?: string;
  date?: string;
}

export interface CompetitorMonitoringIntel {
  newProducts?: CompetitorIntelItem[];
  winningBids?: CompetitorIntelItem[];
  techNews?: CompetitorIntelItem[];
  pricingChanges?: CompetitorIntelItem[];
  customerCases?: CompetitorIntelItem[];
  infoSource?: string;
}

export interface CompetitorUpdateRecord {
  id: string;
  competitorId: string;
  changedFields: Record<string, any>;
  intelPayload?: CompetitorMonitoringIntel;
  source?: string;
  createdAt?: string;
}

export interface Competitor {
  id: string;
  name: string;
  strengths: string[];
  weaknesses: string[];
  pricingRange: string;
  winRate: number;
  pastProjects: string[];
  mainBusiness?: string;
  techRoute?: string;
  typicalCases?: string;
  infoSource?: string;
  monitoringIntel?: CompetitorMonitoringIntel;
  updatedAt?: string | null;
  status?: 'active' | 'inactive' | string;
  priority?: 'key' | 'normal';
  lastEnrichedAt?: string | null;
}

export interface ProposalTemplate {
  id: string;
  title: string;
  category: string;
  description: string;
  content: string;
}

export interface SearchConfig {
  id?: number;
  ruleName?: string;
  status?: string;
  monitorSources: string[];
  keywords: string[];
  excludeKeywords?: string[];
  regions: string[];
  industries: string[];
  categories: string[];
  frequency: string;
  budgetMin?: number;
  budgetMax?: number;
  purchaseTypes?: string[];
  /** 监控发布时间范围：不限 / 近三天 / 近一周 / 近一月 / 近三月 / YYYY-MM-DD~YYYY-MM-DD */
  timeRange?: string;
}

export interface User {
  id: string;
  username: string;
  password?: string; // Optional when sending to frontend
  name: string;
  role: '超级管理员' | '商务负责人' | '商务专员';
  createdAt: string;
}
