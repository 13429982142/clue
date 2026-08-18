<script setup lang="ts">
import { ref, watch, onMounted, computed } from 'vue';
import { 
  Building2, 
  MapPin, 
  Layers, 
  Sparkles, 
  Sliders, 
  FileText, 
  Activity, 
  ShieldCheck, 
  Compass, 
  Database, 
  User, 
  FileCheck, 
  AlertCircle,
  Users,
  LogOut,
  ChevronsLeft,
  ChevronsRight,
  Gauge,
  Briefcase
} from 'lucide-vue-next';

// 导入类型
import { Lead, ScoringRule, AuditLog, Competitor, /* ProposalTemplate, */ SearchConfig, User as UserType, LeadActivity } from './types';

// 导入子组件
import LeadsTab from './components/LeadsTab.vue';
import RulesTab from './components/RulesTab.vue';
import SearchConfigTab from './components/SearchConfigTab.vue';
import ResearchTab from './components/ResearchTab.vue';
// import ProposalTab from './components/ProposalTab.vue';
import CompetitorsTab from './components/CompetitorsTab.vue';
import AuditTab from './components/AuditTab.vue';
import AddLeadModal from './components/AddLeadModal.vue';
import AuthPage from './components/AuthPage.vue';
import UserManagementTab from './components/UserManagementTab.vue';
import SourceHealthTab from './components/SourceHealthTab.vue';
import PushConfigTab from './components/PushConfigTab.vue';
import CustomersTab from './components/CustomersTab.vue';

// 操作员角色
type Role = '超级管理员' | '商务负责人' | '商务专员';

// 当前用户状态
const currentUser = ref<UserType | null>(null);

const currentRole = ref<Role>('超级管理员');
const operatorName = ref<string>('超级管理员陈工');

// 如果存在，从 localStorage 初始化用户
const initUser = () => {
  const saved = localStorage.getItem('clue_user');
  if (saved) {
    try {
      currentUser.value = JSON.parse(saved);
    } catch (e) {
      console.error(e);
    }
  }
};
initUser();

// 获取认证头信息的辅助函数
const getAuthHeaders = () => {
  if (!currentUser.value) return {};
  return {
    'x-user-id': String(currentUser.value.id),
    'x-user-username': encodeURIComponent(currentUser.value.username),
    'x-user-name': encodeURIComponent(currentUser.value.name),
    'x-user-role': encodeURIComponent(currentUser.value.role),
  };
};

// 重写全局 fetch 以自动注入认证头
const originalFetch = window.fetch;
window.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
  const headers = getAuthHeaders();
  const newInit = {
    ...init,
    headers: {
      ...init?.headers,
      ...headers
    }
  };
  return originalFetch(input, newInit);
};

const handleLoginSuccess = (user: UserType) => {
  currentUser.value = user;
  localStorage.setItem('clue_user', JSON.stringify(user));
};

const handleLogout = () => {
  currentUser.value = null;
  localStorage.removeItem('clue_user');
  activeTab.value = 'leads';
};

const confirmLogout = () => {
  showLogoutModal.value = false;
  handleLogout();
};

// 核心数据库数组状态
const leads = ref<Lead[]>([]);
const scoringRule = ref<ScoringRule>({
  budgetWeight: 20,
  matchWeight: 30,
  qualificationWeight: 25,
  stageWeight: 15,
  regionWeight: 10,
  warningThreshold: 80,
});
const auditLogs = ref<AuditLog[]>([]);
const auditTotal = ref(0);
const isAuditRefreshing = ref(false);

// 统一解析审计日志响应（兼容 {items,total} 与旧数组）
const setAuditLogs = (data: any) => {
  if (Array.isArray(data)) {
    auditLogs.value = data;
    auditTotal.value = data.length;
    return;
  }
  if (data && Array.isArray(data.items)) {
    auditLogs.value = data.items;
    auditTotal.value = Number(data.total ?? data.items.length) || 0;
    return;
  }
  auditLogs.value = [];
  auditTotal.value = 0;
};

// 审计页手动刷新：重新拉取审计日志
const handleAuditRefresh = async () => {
  isAuditRefreshing.value = true;
  try {
    const res = await fetch('/api/audit-logs');
    if (res.ok) setAuditLogs(await res.json());
  } catch (err) {
    console.error('Refresh audit logs error:', err);
  } finally {
    isAuditRefreshing.value = false;
  }
};

// 打开审计页时先刷新日志列表
const openAuditTab = () => {
  activeTab.value = 'audit';
  handleAuditRefresh();
};
const competitors = ref<Competitor[]>([]);
const systemUsers = ref<UserType[]>([]);
// const DEFAULT_TEMPLATES: ProposalTemplate[] = [
//   {
//     id: 't1',
//     title: '智慧机电与智能自控节能改造综合方案书',
//     category: '智能自控/机电改造',
//     description: '适用于工业厂房、商业楼宇的机电机泵、风机水泵自控、节能降耗及无人值守自动化设计方案。',
//     content: '',
//   },
//   {
//     id: 't2',
//     title: '污染排放不间断智能监测与异常纠偏方案',
//     category: '高危污染监控',
//     description: '适用于高炉烟气、工业化工污水、特种排放单位的环境在线监控与自动预警纠错布防方案。',
//     content: '',
//   },
// ];
// const templates = ref<ProposalTemplate[]>(DEFAULT_TEMPLATES);

// 标签页类型（包含所有新页面）
const selectedLead = ref<Lead | null>(null);
const activeTab = ref<'leads' | 'rules' | 'search_config' | 'research' | 'competitors' | 'audit' | 'users' | 'source_health' | 'push_config' | 'customers'>('leads');
const leadsTabRef = ref<InstanceType<typeof LeadsTab> | null>(null);
const toast = ref<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);

// 全局居中二次确认弹窗
const confirmDialog = ref<{ message: string; title?: string; resolve: (v: boolean) => void } | null>(null);
const openConfirm = (message: string, title = '操作确认') => {
  return new Promise<boolean>((resolve) => {
    confirmDialog.value = { message, title, resolve };
  });
};
const closeConfirm = (result: boolean) => {
  confirmDialog.value?.resolve(result);
  confirmDialog.value = null;
};
const lastScheduledResultTs = ref('');
const showLogoutModal = ref(false);
const sidebarCollapsed = ref(false);

// 抓取状态 / 网络监控配置状态
const searchConfig = ref<SearchConfig>({
  id: 0,
  ruleName: '默认规则',
  status: 'active',
  monitorSources: [],
  keywords: [],
  excludeKeywords: [],
  regions: [],
  industries: [],
  categories: [],
  frequency: '',
  budgetMin: 0,
  budgetMax: 0,
  purchaseTypes: [],
});

const searchConfigStats = ref({
  keywordCount: 0,
  matchedLeadsCount: 0
});

const isMining = ref(false);
const miningStatus = ref('');
const lastCrawlTimestamp = ref('');

// 预调研状态
const isResearching = ref(false);
const researchGuide = ref('');
const researchReports = ref<any[]>([]);
const activeResearchReport = ref<any | null>(null);

const loadResearchReports = async (leadId: string) => {
  try {
    const res = await fetch(`/api/leads/${leadId}/research`);
    if (res.ok) {
      const list = await res.json();
      researchReports.value = list;
      activeResearchReport.value = list.length > 0 ? list[0] : null;
    }
  } catch (err) {
    console.error('Load research reports error:', err);
  }
};

const handleSelectResearchVersion = (reportId: string) => {
  const found = researchReports.value.find((r: any) => r.id === reportId);
  if (found) activeResearchReport.value = found;
};

// 预调研页从线索池选择线索：同步选中线索并加载其调研档案
const handleSelectResearchLead = (lead: Lead) => {
  selectedLead.value = lead;
  loadResearchReports(lead.id);
};

// 进入预调研页或切换线索时，加载对应调研档案历史
watch([selectedLead, activeTab], ([lead, tab]) => {
  if (tab === 'research' && lead && (lead as any).id) {
    loadResearchReports((lead as any).id);
  } else if (!lead) {
    researchReports.value = [];
    activeResearchReport.value = null;
  }
});

// 当选中的线索变化时自动获取活动
watch(selectedLead, (lead) => {
  if (lead && lead.id) {
    handleFetchActivities(lead.id);
  } else {
    leadActivities.value = [];
  }
});

// 方案起草状态
// const isDraftingProposal = ref(false);
// const selectedTemplateId = ref('');
// const targetPrice = ref('');
// const customSpecs = ref('');

// 竞品对比状态
const enrichingCompetitorId = ref<string>('');
const competitorsTabRef = ref<{ refreshDetailComp?: () => void; openDetailById?: (id: string) => void } | null>(null);

// 弹窗状态
const showAddLeadModal = ref(false);

const normalizeScoringRule = (raw: any): ScoringRule => ({
  budgetWeight: Number(raw?.budgetWeight ?? 20),
  matchWeight: Number(raw?.matchWeight ?? 30),
  qualificationWeight: Number(raw?.qualificationWeight ?? 25),
  stageWeight: Number(raw?.stageWeight ?? 15),
  regionWeight: Number(raw?.regionWeight ?? 10),
  warningThreshold: Number(raw?.warningThreshold ?? 80),
});

// 从 API 加载数据的方法
const fetchData = async () => {
  try {
    const leadsRes = await fetch('/api/leads');
    const leadsData = await leadsRes.json();
    if (Array.isArray(leadsData)) {
      leads.value = leadsData;
      
      // 检查当前选中的线索是否仍在已加载的列表中（尊重数据隔离）
      if (selectedLead.value) {
        const matchingLive = leadsData.find((l: any) => l.id === selectedLead.value?.id);
        if (matchingLive) {
          selectedLead.value = matchingLive;
        } else {
          // 如果选中的线索不在列表中（由于角色切换/数据隔离），重置它
          selectedLead.value = leadsData.length > 0 ? leadsData[0] : null;
        }
      } else if (leadsData.length > 0) {
        selectedLead.value = leadsData[0];
      }
    } else {
      console.error('Leads data is not an array:', leadsData);
      leads.value = [];
    }

    const rulesRes = await fetch('/api/rules');
    if (rulesRes.ok) {
      const rulesData = await rulesRes.json();
      scoringRule.value = normalizeScoringRule(rulesData);
    } else {
      scoringRule.value = normalizeScoringRule(null);
    }

    const logsRes = await fetch('/api/audit-logs');
    const logsData = await logsRes.json();
    setAuditLogs(logsData);

    const compRes = await fetch('/api/competitors');
    const compData = await compRes.json();
    if (Array.isArray(compData)) {
      competitors.value = compData;
    } else {
      console.error('Competitors data is not an array:', compData);
      competitors.value = [];
    }

    // if (!selectedTemplateId.value && templates.value.length > 0) {
    //   selectedTemplateId.value = templates.value[0].id;
    // }

    // 从后端获取搜索配置
    const searchConfigRes = await fetch('/api/search-configs');
    if (searchConfigRes.ok) {
      const searchConfigsData = await searchConfigRes.json();
      if (Array.isArray(searchConfigsData) && searchConfigsData.length > 0) {
        searchConfig.value = searchConfigsData[0];
      }
    }

    // 从后端获取搜索配置统计
    const statsRes = await fetch('/api/search-config/stats');
    if (statsRes.ok) {
      const statsData = await statsRes.json();
      searchConfigStats.value = statsData;
    }

    // 如果当前用户是超级管理员或商务负责人，获取用户列表
    if (currentUser.value && (currentUser.value.role === '超级管理员' || currentUser.value.role === '商务负责人')) {
      const usersRes = await fetch('/api/users');
      if (usersRes.ok) {
        const usersData = await usersRes.json();
        if (Array.isArray(usersData)) {
          systemUsers.value = usersData;
        } else {
          systemUsers.value = [];
        }
      } else {
        systemUsers.value = [];
      }
    } else {
      systemUsers.value = [];
    }
  } catch (error) {
    console.error('Error fetching baseline API states in Vue root:', error);
  }
};

// 监听 currentUser 以同步旧的角色和名称引用
watch(currentUser, (user) => {
  if (user) {
    currentRole.value = user.role;
    operatorName.value = user.name;
    // 用户切换时重置选中的线索以确保数据隔离
    selectedLead.value = null;
    // 用户变更/登录时触发数据获取
    fetchData();
  } else {
    currentRole.value = '商务专员';
    operatorName.value = '访客';
    leads.value = [];
    selectedLead.value = null;
    auditLogs.value = [];
    competitors.value = [];
  }
}, { immediate: true });

// 生命周期
onMounted(() => {
  fetchData();
  // 轮询 AI 定时抓取结果
  setInterval(async () => {
    try {
      const res = await fetch('/api/leads/scheduled-result');
      if (!res.ok) return;
      const data = await res.json();
      if (data.timestamp && data.timestamp !== lastScheduledResultTs.value) {
        lastScheduledResultTs.value = data.timestamp;
        if (data.summary) {
          toast.value = { message: `AI 定时抓取完成：${data.summary}`, type: 'info' };
          setTimeout(() => { toast.value = null; }, 6000);
          await fetchData();
        }
      }
    } catch (e) {
      // 忽略轮询错误
    }
  }, 30000); // 每30秒轮询一次
});

// 切换到线索 tab 时刷新数据
watch(activeTab, (newTab, oldTab) => {
  if (newTab === 'leads' && oldTab !== 'leads') {
    fetchData();
  }
});

// 角色同步现在由 watch(currentUser) 处理

// 通过 API 调用的核心业务变更（翻译自 App.tsx 操作）

// 更新权重
const handleUpdateWeights = async (newWeights: Partial<ScoringRule>): Promise<boolean> => {
  const previousRule = { ...scoringRule.value };
  scoringRule.value = normalizeScoringRule({
    ...scoringRule.value,
    ...newWeights,
  });

  try {
    const response = await fetch('/api/rules', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        budgetWeight: scoringRule.value.budgetWeight,
        matchWeight: scoringRule.value.matchWeight,
        stageWeight: scoringRule.value.stageWeight,
        qualificationWeight: scoringRule.value.qualificationWeight,
        regionWeight: scoringRule.value.regionWeight,
        warningThreshold: scoringRule.value.warningThreshold,
        ...newWeights,
        operatorName: operatorName.value,
        operatorRole: currentRole.value
      })
    });
    if (response.ok) {
      const result = await response.json();
      scoringRule.value = normalizeScoringRule(result.rule);
      fetchData();
      return true;
    } else {
      scoringRule.value = previousRule;
      return false;
    }
  } catch (err) {
    scoringRule.value = previousRule;
    console.error('Failed to change system rules:', err);
    return false;
  }
};

// 更新搜索配置（4.1.1: 多套监测规则并行, 配置提交后实时生效）
const handleUpdateSearchConfig = async (newConfig: any) => {
  try {
    const updated = { ...searchConfig.value, ...newConfig };
    searchConfig.value = updated;
    
    const configId = updated.id || 0;
    const payload = {
      ruleName: updated.ruleName || '默认规则',
      status: updated.status || 'active',
      monitorSources: Array.isArray(updated.monitorSources) ? updated.monitorSources : [],
      keywords: Array.isArray(updated.keywords) ? updated.keywords : [],
      excludeKeywords: Array.isArray(updated.excludeKeywords) ? updated.excludeKeywords : [],
      regions: Array.isArray(updated.regions) ? updated.regions : [],
      industries: Array.isArray(updated.industries) ? updated.industries : [],
      categories: Array.isArray(updated.categories) ? updated.categories : [],
      frequency: updated.frequency || '每天早上8:00实时',
      budgetMin: updated.budgetMin || 0,
      budgetMax: updated.budgetMax || 2000,
      purchaseTypes: Array.isArray(updated.purchaseTypes) ? updated.purchaseTypes : [],
      timeRange: updated.timeRange || '不限',
      operatorName: operatorName.value,
      operatorRole: currentRole.value
    };

    let res;
    if (configId && configId !== 0 && configId !== '0') {
      res = await fetch(`/api/search-configs/${configId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
    } else {
      res = await fetch('/api/search-configs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
    }
    if (res.ok) {
      const result = await res.json();
      searchConfig.value = result.searchConfig ?? result;
      const logsRes = await fetch('/api/audit-logs');
      setAuditLogs(await logsRes.json());
    } else {
      const err = await res.json().catch(() => ({}));
      console.error('保存监测规则失败:', err.errors || err.error);
    }
  } catch (err) {
    console.error('Error saving search config:', err);
  }
};

// 触发网络爬虫
const handleTriggerMiningQuery = async () => {
  isMining.value = true;
  miningStatus.value = '正在连接公网招采平台...';
  
  const steps = [
    '正在抓取中国政府采购网、公共资源交易平台公告列表...',
    '正在解析详情页并匹配关键词与黑名单规则...',
    '正在与现有线索池去重比对并标准化字段...',
    '正在计算 5 维加权评分并写入线索池...'
  ];

  for (let i = 0; i < steps.length; i++) {
    await new Promise(r => setTimeout(r, 800));
    miningStatus.value = steps[i];
  }

  try {
    const res = await fetch('/api/gemini/scrape', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ searchConfig: searchConfig.value })
    });
    const result = await res.json();
    isMining.value = false;
    miningStatus.value = '';
    if (!res.ok) {
      alert(result.error || result.details || '抓取失败，请检查网络与数据源配置');
      return;
    }
    // 记录本次爬取时间戳（东八区），用于前端标记新线索
    const d = new Date();
    const cst = new Date(d.getTime() + 8 * 60 * 60 * 1000);
    lastCrawlTimestamp.value = cst.toISOString().slice(0, 19).replace('T', ' ');
    if (result.stats) {
      const msg =
        `扫描 ${result.stats.scannedCount ?? 0} 条，` +
        `新增 ${result.stats.createdCount} 条，` +
        `重复 ${result.stats.skippedDuplicateCount} 条，` +
        `过滤丢弃 ${result.stats.filteredCount ?? 0} 条。`;
      // 非阻塞提示（写入 miningStatus 短暂显示）
      miningStatus.value = `✅ 抓取完成：${msg}` ;
      setTimeout(() => { miningStatus.value = ''; }, 4000);
      toast.value = { message: `AI 抓取完成：${msg}`, type: 'success' };
      setTimeout(() => { toast.value = null; }, 6000);
    }
    fetchData();
  } catch (err) {
    isMining.value = false;
    miningStatus.value = '';
    alert('抓取请求失败，请检查网络连接后重试');
    console.error(err);
  }
};

// 线索状态流转更新
const handleLeadStatusChange = async (payload: { leadId: string; status: Lead['status']; returnReason?: string }) => {
  try {
    const patchData: Partial<Lead> & { operatorName: string; operatorRole: string; returnReason?: string } = {
      status: payload.status,
      operatorName: operatorName.value,
      operatorRole: currentRole.value
    };

    if (payload.returnReason) {
      patchData.returnReason = payload.returnReason;
    }

    if (payload.status === '跟进中' && !selectedLead.value?.followUpPerson) {
      patchData.followUpPerson = operatorName.value;
    }

    const response = await fetch(`/api/leads/${payload.leadId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(patchData)
    });

    if (response.ok) {
      const updated = await response.json();
      leads.value = leads.value.map(l => l.id === payload.leadId ? updated : l);
      selectedLead.value = updated;
      const logsRes = await fetch('/api/audit-logs');
      setAuditLogs(await logsRes.json());
    } else {
      const errData = await response.json();
      alert(`状态更新失败: ${errData.error || errData.detail || '未知错误'}`);
    }
  } catch (err) {
    console.error('Failed to patch lead status:', err);
  }
};

// 直接分配人员
const handleAssignPerson = async (payload: { leadId: string; person: string }) => {
  try {
    const response = await fetch(`/api/leads/${payload.leadId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        followUpPerson: payload.person,
        operatorName: operatorName.value,
        operatorRole: currentRole.value
      })
    });
    if (response.ok) {
      const updated = await response.json();
      leads.value = leads.value.map(l => l.id === payload.leadId ? updated : l);
      selectedLead.value = updated;
      const logsRes = await fetch('/api/audit-logs');
      setAuditLogs(await logsRes.json());
    }
  } catch (err) {
    console.error(err);
  }
};

// 直接保存文本备注
const handleSaveNotes = async (payload: { leadId: string; notes: string }) => {
  try {
    const response = await fetch(`/api/leads/${payload.leadId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        notes: payload.notes,
        operatorName: operatorName.value,
        operatorRole: currentRole.value
      })
    });
    if (response.ok) {
      const updated = await response.json();
      leads.value = leads.value.map(l => l.id === payload.leadId ? updated : l);
      selectedLead.value = updated;
    }
  } catch (err) {
    console.error(err);
  }
};

// 手动补全招投标联系人 / 电话
const handleUpdateContact = async (payload: {
  leadId: string;
  contactName: string;
  contactPhone: string;
}) => {
  try {
    const response = await fetch(`/api/leads/${payload.leadId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contactName: payload.contactName,
        contactPhone: payload.contactPhone,
        operatorName: operatorName.value,
        operatorRole: currentRole.value,
      }),
    });
    if (response.ok) {
      const updated = await response.json();
      leads.value = leads.value.map((l) => (l.id === payload.leadId ? updated : l));
      selectedLead.value = updated;
      const logsRes = await fetch('/api/audit-logs');
      if (logsRes.ok) setAuditLogs(await logsRes.json());
    } else {
      const detail = await response.json().catch(() => ({}));
      alert(detail.detail || '保存联系人失败');
    }
  } catch (err) {
    console.error(err);
    alert('保存联系人失败');
  }
};

// 删除/废弃线索
const handleDeleteLead = async (leadId: string) => {
  if (!await openConfirm('您确定要将该商务线索从池子内彻底移除吗？此流程将同步载入系统安全追踪审计。', '移除线索确认')) return;
  try {
    const response = await fetch(`/api/leads/${leadId}`, { method: 'DELETE' });
    if (response.ok) {
      const remaining = leads.value.filter(l => l.id !== leadId);
      leads.value = remaining;
      if (remaining.length > 0) {
        selectedLead.value = remaining[0];
      } else {
        selectedLead.value = null;
      }
      const logsRes = await fetch('/api/audit-logs');
      setAuditLogs(await logsRes.json());
    }
  } catch (err) {
    console.error(err);
  }
};

// 线索活动（跟进记录）
const leadActivities = ref<LeadActivity[]>([]);

const handleFetchActivities = async (leadId: string) => {
  if (!leadId) {
    leadActivities.value = [];
    return;
  }
  try {
    const res = await fetch(`/api/leads/${leadId}/activities`);
    if (res.ok) {
      leadActivities.value = await res.json();
    } else {
      leadActivities.value = [];
    }
  } catch (err) {
    console.error('Fetch activities error:', err);
    leadActivities.value = [];
  }
};

const handleAddActivity = async (payload: { leadId: string; content: string; activityType?: string }) => {
  try {
    const res = await fetch(`/api/leads/${payload.leadId}/activities`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        content: payload.content,
        activityType: payload.activityType || 'comment',
        operatorName: operatorName.value,
      })
    });
    if (res.ok) {
      const newActivity = await res.json();
      leadActivities.value = [...leadActivities.value, newActivity];
      return true;
    }
    return false;
  } catch (err) {
    console.error('Add activity error:', err);
    return false;
  }
};

// 触发预调研：多源聚合 + 痛点报告生成 + 版本化归档
const handleTriggerPreResearch = async (leadId: string) => {
  isResearching.value = true;
  try {
    const response = await fetch(`/api/leads/${leadId}/research`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        customGuide: researchGuide.value,
        operatorName: operatorName.value
      })
    });
    if (response.ok) {
      const newReport = await response.json();
      await loadResearchReports(leadId);
      activeResearchReport.value = newReport;

      const updatedLeadRes = await fetch('/api/leads');
      const updatedLeads = await updatedLeadRes.json();
      leads.value = updatedLeads;
      const refLead = updatedLeads.find((l: any) => l.id === leadId);
      if (refLead) selectedLead.value = refLead;

      const logsRes = await fetch('/api/audit-logs');
      setAuditLogs(await logsRes.json());
    } else {
      const detail = await response.json().catch(() => ({}));
      alert(detail.detail || '预调研生成失败');
    }
  } catch (err) {
    console.error('Trigger Research error:', err);
  } finally {
    isResearching.value = false;
  }
};

// 标书/方案生成功能暂未实现：按钮置为无操作，点击不触发任何请求、不报错、不改 loading。
// const handleTriggerDraftProposal = async (_leadId: string) => {
//   return;
// };

// 刷新竞品库 + 审计日志（竞品相关操作后统一调用）
const refreshCompetitors = async () => {
  try {
    const compRes = await fetch('/api/competitors');
    if (compRes.ok) competitors.value = await compRes.json();
    const logsRes = await fetch('/api/audit-logs');
    if (logsRes.ok) setAuditLogs(await logsRes.json());
  } catch (err) {
    console.error('Refresh competitors error:', err);
  }
};

// 新增竞品（同名 409 时提示合并 / 转编辑）
const handleAddCompetitor = async (form: Partial<Competitor>) => {
  try {
    const response = await fetch('/api/competitors', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: form.name,
        strengths: form.strengths || [],
        weaknesses: form.weaknesses || [],
        pricingRange: form.pricingRange || '',
        winRate: form.winRate ?? 50,
        mainBusiness: form.mainBusiness || '',
        techRoute: form.techRoute || '',
        typicalCases: form.typicalCases || '',
        infoSource: form.infoSource || '',
        operatorName: operatorName.value,
        operatorRole: currentRole.value
      })
    });
    if (response.ok) {
      await refreshCompetitors();
      return;
    }
    if (response.status === 409) {
      const detail = await response.json().catch(() => ({}));
      const info = detail?.detail || {};
      const existingId = info.existingId;
      const existingName = info.existingName || form.name;
      if (existingId && await openConfirm(`${info.message || `已存在同名竞品「${existingName}」`}\n\n点击「确定」改为更新该已存在竞品，点击「取消」放弃。`, '同名竞品处理')) {
        await handleUpdateCompetitor({ ...form, id: existingId } as Partial<Competitor> & { id: string });
      }
      return;
    }
    const errDetail = await response.json().catch(() => ({}));
    alert(typeof errDetail.detail === 'string' ? errDetail.detail : '新增竞品失败');
  } catch (err) {
    console.error('Add competitor error:', err);
  }
};

// 编辑竞品资料
const handleUpdateCompetitor = async (form: Partial<Competitor> & { id: string }) => {
  try {
    const response = await fetch(`/api/competitors/${form.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: form.name,
        strengths: form.strengths,
        weaknesses: form.weaknesses,
        pricingRange: form.pricingRange,
        winRate: form.winRate,
        mainBusiness: form.mainBusiness,
        techRoute: form.techRoute,
        typicalCases: form.typicalCases,
        infoSource: form.infoSource,
        priority: form.priority,
        operatorName: operatorName.value,
        operatorRole: currentRole.value
      })
    });
    if (response.ok) {
      await refreshCompetitors();
    } else {
      const detail = await response.json().catch(() => ({}));
      alert(typeof detail.detail === 'string' ? detail.detail : '更新竞品失败');
    }
  } catch (err) {
    console.error('Update competitor error:', err);
  }
};

// 失效 / 启用（软失效）
const handleToggleCompetitorStatus = async (payload: { id: string; status: 'active' | 'inactive' }) => {
  try {
    const response = await fetch(`/api/competitors/${payload.id}/status`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        status: payload.status,
        operatorName: operatorName.value,
        operatorRole: currentRole.value
      })
    });
    if (response.ok) {
      await refreshCompetitors();
    }
  } catch (err) {
    console.error('Toggle competitor status error:', err);
  }
};

const handleDeleteCompetitor = async (compId: string) => {
  if (!await openConfirm('确定删除该竞品及其全部更新留痕？删除后不可恢复。', '删除竞品确认')) return;
  try {
    const res = await fetch(`/api/competitors/${compId}`, { method: 'DELETE' });
    if (!res.ok) {
      const data = await res.json().catch(() => null);
      window.alert(data?.detail || '删除竞品失败');
      return;
    }
    competitors.value = competitors.value.filter((c: any) => c.id !== compId);
    const logsRes = await fetch('/api/audit-logs');
    if (logsRes.ok) setAuditLogs(await logsRes.json());
  } catch (err) {
    console.error('Delete competitor error:', err);
    window.alert('网络异常，删除失败，请重试');
  }
};

// DeepSeek 全网检索补全 / 更新
const handleEnrichCompetitor = async (compId: string) => {
  enrichingCompetitorId.value = compId;
  try {
    const response = await fetch(`/api/competitors/${compId}/enrich`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        operatorName: operatorName.value,
        operatorRole: currentRole.value
      })
    });
    const result = await response.json().catch(() => ({}));
    if (response.ok) {
      await refreshCompetitors();
      competitorsTabRef.value?.refreshDetailComp?.();
      alert(result.message || '检索完成');
    } else {
      alert(typeof result.detail === 'string' ? result.detail : '竞品智能补全失败');
    }
  } catch (err) {
    console.error('Enrich competitor error:', err);
  } finally {
    enrichingCompetitorId.value = '';
  }
};

// 处理弹窗提交的手动线索创建
const handleCreateManualLead = async (formData: any) => {
  try {
    const response = await fetch('/api/leads', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        ...formData,
        operatorName: operatorName.value,
        operatorRole: currentRole.value
      })
    });
    if (response.ok) {
      const newlyCreated = await response.json();
      leads.value = [newlyCreated, ...leads.value];
      selectedLead.value = newlyCreated;
      showAddLeadModal.value = false;
      
      const logsRes = await fetch('/api/audit-logs');
      setAuditLogs(await logsRes.json());
    }
  } catch (err) {
    console.error(err);
  }
};

// 将线索转化为客户（4.2.4）
const handleConvertLead = async (leadId: string) => {
  if (!await openConfirm('确认将该线索转化为客户并生成项目台账？', '转为客户确认')) return;
  console.log('[CONVERT] Frontend: calling convert API for leadId=', leadId);
  try {
    const res = await fetch(`/api/leads/${leadId}/convert`, {
      method: 'POST',
      headers: getAuthHeaders(),
    });
    console.log('[CONVERT] Frontend: response status=', res.status);
    if (res.ok) {
      const data = await res.json();
      console.log('[CONVERT] Frontend: success data=', data);
      alert(`线索已转化为客户「${data.customer.company}」并生成立项项目「${data.project.projectName}」`);
      fetchData();
    } else {
      const err = await res.json().catch(() => ({ error: '未知错误' }));
      console.log('[CONVERT] Frontend: error response=', err);
      alert(err.error || '转化失败');
    }
  } catch (err) {
    console.error('[CONVERT] Frontend: fetch error=', err);
  }
};

// 收藏/取消收藏线索
const handleToggleFavorite = async (leadId: string) => {
  try {
    const res = await fetch(`/api/leads/${leadId}/toggle-favorite`, {
      method: 'POST',
      headers: getAuthHeaders(),
    });
    if (res.ok) {
      const updated = await res.json();
      leads.value = leads.value.map(l => l.id === leadId ? updated : l);
      if (selectedLead.value?.id === leadId) selectedLead.value = updated;
      toast.value = {
        message: updated.isFavorite ? '已收藏该线索' : '已取消收藏',
        type: 'success',
      };
      setTimeout(() => { toast.value = null; }, 2000);
    }
  } catch (err) {
    console.error('Toggle favorite error:', err);
  }
};

// Excel 导入
const handleImportLeads = async (file: File, duplicateAction: 'skip' | 'overwrite') => {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('duplicateAction', duplicateAction);
  try {
    const res = await fetch('/api/leads/import', {
      method: 'POST',
      body: formData,
    });
    if (res.ok) {
      const result = await res.json();
      const parts = [];
      if (result.imported > 0) parts.push(`新增 ${result.imported} 条`);
      if (result.overwritten > 0) parts.push(`覆盖 ${result.overwritten} 条`);
      if (result.duplicated > 0) parts.push(`跳过重复 ${result.duplicated} 条`);
      if ((result.errors?.length || 0) > 0) {
        parts.push(`失败 ${result.errors.length} 条`);
        toast.value = { message: `导入完成: ${parts.join('，')}\n\n${result.errors.join('\n')}`, type: 'error' };
      } else {
        toast.value = { message: `导入完成: ${parts.join('，')}`, type: 'success' };
      }
      setTimeout(() => { toast.value = null; }, 3000);
      // 用后端返回的导入时间设置时间戳，让新线索显示「新」标签
      if (result.importTime) {
        lastCrawlTimestamp.value = result.importTime;
      }
      await fetchData();
      leadsTabRef.value?.closeImportModal();
    } else {
      const err = await res.json().catch(() => ({}));
      toast.value = { message: err.detail || err.error || '导入失败', type: 'error' };
      setTimeout(() => { toast.value = null; }, 3000);
      leadsTabRef.value?.closeImportModal();
    }
  } catch (err) {
    console.error(err);
    toast.value = { message: '网络异常，导入失败', type: 'error' };
    setTimeout(() => { toast.value = null; }, 3000);
    leadsTabRef.value?.closeImportModal();
  }
};

const handleDownloadTemplate = async () => {
  try {
    const res = await fetch('/api/leads/template', { headers: getAuthHeaders() });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      alert(err.detail || err.error || '模板下载失败');
      return;
    }
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = '线索导入模板.xlsx';
    a.click();
    URL.revokeObjectURL(url);
  } catch (err) {
    console.error(err);
    alert('模板下载失败，请稍后重试');
  }
};

</script>

<template>
  <div v-if="!currentUser">
    <AuthPage @login-success="handleLoginSuccess" />
  </div>
  <div v-else class="light-gray-ui flex h-screen bg-slate-100 text-slate-900 font-sans select-none overflow-hidden antialiased">
    
    <!-- 左侧导航栏 -->
    <div :class="[
      'border-r border-slate-800 bg-slate-950 flex flex-col shrink-0 transition-[width] duration-300',
      sidebarCollapsed ? 'w-20' : 'w-64'
    ]">
      
      <!-- Logo 品牌头部包装 -->
      <div :class="[
        'p-4 border-b border-slate-800 flex items-center shrink-0 transition-all duration-300',
        sidebarCollapsed ? 'justify-center' : 'justify-between space-x-3'
      ]">
        <div :class="sidebarCollapsed ? '' : 'flex items-center space-x-3 min-w-0'">
          <div class="bg-gradient-to-tr from-cyan-500 to-indigo-600 p-2 rounded-xl text-white shadow-lg shadow-cyan-500/20 shrink-0">
            <Building2 class="h-6 w-6 stroke-[2]" style="color: #ffffff" />
          </div>
          <div v-show="!sidebarCollapsed" class="min-w-0">
            <h1 class="text-md font-extrabold tracking-tight text-slate-900 truncate">
              污水智控·商机大脑
            </h1>
          </div>
        </div>
        <button
          v-if="!sidebarCollapsed"
          @click="sidebarCollapsed = true"
          class="shrink-0 text-slate-500 hover:text-slate-300 transition p-1.5 rounded-lg hover:bg-slate-800/60"
          title="收起侧边栏"
        >
          <ChevronsLeft class="h-4 w-4" />
        </button>
      </div>

      <!-- 导航链接（符合规范的标签页导航） -->
      <nav :class="['flex-1 py-6 space-y-1.5 overflow-y-auto transition-all duration-300', sidebarCollapsed ? 'px-2' : 'px-4']">
        
        <!-- 标签页 1. 线索列表主界面 -->
        <button 
          @click="activeTab = 'leads'"
          :class="[
            'w-full flex items-center py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            sidebarCollapsed ? 'justify-center px-2' : 'justify-start px-4 space-x-3',
            activeTab === 'leads' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <Compass class="h-4 w-4 shrink-0" />
          <span v-show="!sidebarCollapsed">全网监测与线索</span>
        </button>

        <!-- 标签页 2. 规则 -->
        <button 
          @click="activeTab = 'rules'"
          :class="[
            'w-full flex items-center py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            sidebarCollapsed ? 'justify-center px-2' : 'justify-start px-4 space-x-3',
            activeTab === 'rules' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <Sliders class="h-4 w-4 shrink-0" />
          <span v-show="!sidebarCollapsed">5维打分公式权重</span>
        </button>

        <!-- 标签页 3. 关键词配置 -->
        <button 
          v-if="currentUser && (currentUser.role === '超级管理员' || currentUser.role === '商务负责人')"
          @click="activeTab = 'search_config'"
          :class="[
            'w-full flex items-center py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            sidebarCollapsed ? 'justify-center px-2' : 'justify-start px-4 space-x-3',
            activeTab === 'search_config' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <Database class="h-4 w-4 shrink-0" />
          <span v-show="!sidebarCollapsed">网监抓取黑白名单</span>
        </button>

        <!-- 标签页 4. 预调研 -->
        <button 
          @click="activeTab = 'research'"
          :class="[
            'w-full flex items-center py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            sidebarCollapsed ? 'justify-center px-2' : 'justify-start px-4 space-x-3',
            activeTab === 'research' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <Sparkles class="h-4 w-4 text-cyan-400 shrink-0" />
          <span v-show="!sidebarCollapsed">AI 智能预调研</span>
        </button>

<!--        标签页 5. 方案 -->
<!--        <button
          @click="activeTab = 'proposal'"
          :class="[
            'w-full flex items-center space-x-3 px-4 py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            activeTab === 'proposal' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <FileText class="h-4 w-4 text-indigo-400 shrink-0" />
          <span>AI 标书方案生成</span>
        </button>-->

        <!-- 标签页 6. 竞品矩阵 -->
        <button 
          @click="activeTab = 'competitors'"
          :class="[
            'w-full flex items-center py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            sidebarCollapsed ? 'justify-center px-2' : 'justify-start px-4 space-x-3',
            activeTab === 'competitors' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <Layers class="h-4 w-4 text-purple-400 shrink-0" />
          <span v-show="!sidebarCollapsed">竞品动态监测库</span>
        </button>

        <!-- 标签页 7. 审计日志 -->
        <button 
          @click="openAuditTab"
          :class="[
            'w-full flex items-center py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            sidebarCollapsed ? 'justify-center px-2' : 'justify-start px-4 space-x-3',
            activeTab === 'audit' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <Activity class="h-4 w-4 text-emerald-400 shrink-0" />
          <span v-show="!sidebarCollapsed">跟踪及流转审计</span>
        </button>

        <!-- 标签页 8. 用户管理（仅管理员） -->
        <button 
          v-if="currentUser && currentUser.role === '超级管理员'"
          @click="activeTab = 'users'"
          :class="[
            'w-full flex items-center py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            sidebarCollapsed ? 'justify-center px-2' : 'justify-start px-4 space-x-3',
            activeTab === 'users' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <Users class="h-4 w-4 text-cyan-400 shrink-0" />
          <span v-show="!sidebarCollapsed">系统用户管理</span>
        </button>

        <!-- 标签页 9. 数据源健康（仅管理员） -->
        <button 
          v-if="currentUser && (currentUser.role === '超级管理员' || currentUser.role === '商务负责人')"
          @click="activeTab = 'source_health'"
          :class="[
            'w-full flex items-center py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            sidebarCollapsed ? 'justify-center px-2' : 'justify-start px-4 space-x-3',
            activeTab === 'source_health' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <Gauge class="h-4 w-4 text-emerald-400 shrink-0" />
          <span v-show="!sidebarCollapsed">数据源健康监控</span>
        </button>

        <!-- 标签页 10. 推送配置 -->
<!--        <button
          v-if="currentUser && (currentUser.role === '超级管理员' || currentUser.role === '商务负责人')"
          @click="activeTab = 'push_config'"
          :class="[
            'w-full flex items-center space-x-3 px-4 py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            activeTab === 'push_config' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <Sliders class="h-4 w-4 text-amber-400 shrink-0" />
          <span>推送规则配置</span>
        </button>-->

        <!-- 标签页 11. 客户与项目 -->
        <button 
          v-if="currentUser && (currentUser.role === '超级管理员' || currentUser.role === '商务负责人')"
          @click="activeTab = 'customers'"
          :class="[
            'w-full flex items-center py-3 rounded-xl text-xs font-bold transition flex-row items-center focus:outline-none',
            sidebarCollapsed ? 'justify-center px-2' : 'justify-start px-4 space-x-3',
            activeTab === 'customers' 
              ? 'bg-cyan-500 text-white menu-item-active shadow-lg shadow-cyan-500/10' 
              : 'text-slate-300 hover:bg-slate-900 hover:text-slate-200'
          ]"
        >
          <Briefcase class="h-4 w-4 text-indigo-400 shrink-0" />
          <span v-show="!sidebarCollapsed">客户档案与项目台账</span>
        </button>

      </nav>

      <!-- 已登录用户个人资料与退出 -->
      <div v-if="currentUser" class="p-4 border-t border-slate-800 bg-slate-950/80 space-y-3 shrink-0">
        <!-- 展开侧边栏按钮（收起时显示） -->
        <button
          v-if="sidebarCollapsed"
          @click="sidebarCollapsed = false"
          class="w-full flex items-center justify-center py-2 rounded-xl text-slate-500 hover:text-slate-300 hover:bg-slate-800/60 transition"
          title="展开侧边栏"
        >
          <ChevronsRight class="h-4 w-4" />
        </button>

        <div v-if="!sidebarCollapsed" class="flex items-center justify-between text-xs text-slate-400 font-mono">
          <span>当前登录用户</span>
          <ShieldCheck class="h-3.5 w-3.5 text-cyan-500" />
        </div>

        <div :class="[
          'bg-slate-900 rounded-xl border border-slate-800',
          sidebarCollapsed ? 'p-2 flex justify-center' : 'p-3 space-y-2'
        ]">
          <div :class="sidebarCollapsed ? '' : 'flex items-center space-x-2'">
            <div class="w-7 h-7 rounded-full bg-slate-950 border border-slate-800 flex items-center justify-center text-xs font-bold text-cyan-400">
              {{ currentUser.name.charAt(0) }}
            </div>
            <div v-show="!sidebarCollapsed" class="min-w-0 flex-1">
              <span class="block text-xs font-bold text-slate-200 truncate">{{ currentUser.name }}</span>
              <span class="block text-xs text-slate-400 font-mono truncate">{{ currentUser.role }}</span>
            </div>
          </div>
        </div>

        <button 
          @click="showLogoutModal = true"
          :class="[
            'w-full bg-slate-900 hover:bg-rose-950/20 border border-slate-800 hover:border-rose-800/30 text-slate-300 hover:text-rose-400 text-xs font-bold py-2 rounded-xl flex items-center transition',
            sidebarCollapsed ? 'justify-center px-2' : 'justify-center space-x-1.5 px-3'
          ]"
        >
          <LogOut class="h-3.5 w-3.5 shrink-0" />
          <span v-show="!sidebarCollapsed">安全退出登录</span>
        </button>
      </div>

    </div>

    <!-- 主右侧内容区域容器 -->
    <div class="flex-1 flex flex-col overflow-hidden bg-slate-900/40">
      
      <!-- 标签页视图切换引擎 -->
      <main class="flex-1 flex overflow-hidden">
        
        <!-- 标签页 1. 线索工作区视图 -->
        <LeadsTab 
          ref="leadsTabRef"
          v-if="activeTab === 'leads'"
          :leads="leads"
          :selected-lead="selectedLead"
          :search-config="searchConfig"
          :search-config-stats="searchConfigStats"
          :is-mining="isMining"
          :mining-status="miningStatus"
          :last-crawl-timestamp="lastCrawlTimestamp"
          :current-role="currentRole"
          :operator-name="operatorName"
          :scoring-rule="scoringRule"
          :system-users="systemUsers"
          :lead-activities="leadActivities"
          @select-lead="selectedLead = $event"
          @open-add-modal="showAddLeadModal = true"
          @trigger-mining="handleTriggerMiningQuery"
          @status-change="handleLeadStatusChange"
          @assign-person="handleAssignPerson"
          @save-notes="handleSaveNotes"
          @update-contact="handleUpdateContact"
          @delete-lead="handleDeleteLead"
          @switch-tab="activeTab = $event"
          @add-activity="handleAddActivity"
          @convert-lead="handleConvertLead"
          @toggle-favorite="handleToggleFavorite"
          @import-leads="handleImportLeads"
          @download-template="handleDownloadTemplate"
        />

        <!-- 标签页 2. 公式规则设置 -->
        <RulesTab 
          v-else-if="activeTab === 'rules'"
          :scoring-rule="scoringRule"
          @update-weights="handleUpdateWeights"
        />

        <!-- 标签页 3. 抓取配置 -->
        <SearchConfigTab 
          v-else-if="activeTab === 'search_config'"
          :search-config="searchConfig"
          :search-config-stats="searchConfigStats"
          :is-mining="isMining"
          :mining-status="miningStatus"
          @update-config="handleUpdateSearchConfig"
          @trigger-mining="handleTriggerMiningQuery"
        />

        <!-- 标签页 4. AI 企业预调研分析 -->
        <ResearchTab 
          v-else-if="activeTab === 'research'"
          :selected-lead="selectedLead"
          :leads="leads"
          :is-researching="isResearching"
          :research-guide="researchGuide"
          :reports="researchReports"
          :active-report="activeResearchReport"
          :current-role="currentRole"
          @update-guide="researchGuide = $event"
          @trigger-research="handleTriggerPreResearch"
          @select-version="handleSelectResearchVersion"
          @select-lead="handleSelectResearchLead"
        />

<!--        标签页 5. AI 标准技术投标方案模板扩展 -->
<!--        <ProposalTab 
          v-else-if="activeTab === 'proposal'"
          :selected-lead="selectedLead"
          :templates="templates"
          :is-drafting-proposal="isDraftingProposal"
          :selected-template-id="selectedTemplateId"
          :target-price="targetPrice"
          :custom-specs="customSpecs"
          @update-template="selectedTemplateId = $event"
          @update-price="targetPrice = $event"
          @update-specs="customSpecs = $event"
          @trigger-proposal="handleTriggerDraftProposal"
        />-->

        <!-- 标签页 6. AI 竞品对比 PK -->
        <CompetitorsTab
          ref="competitorsTabRef"
          v-else-if="activeTab === 'competitors'"
          :competitors="competitors"
          :enriching-competitor-id="enrichingCompetitorId"
          :current-role="currentRole"
          @add-competitor="handleAddCompetitor"
          @update-competitor="handleUpdateCompetitor"
          @toggle-status="handleToggleCompetitorStatus"
          @enrich-competitor="handleEnrichCompetitor"
          @delete-competitor="handleDeleteCompetitor"
        />

        <!-- 标签页 7. 审计控制流日志跟踪 -->
        <AuditTab 
          v-else-if="activeTab === 'audit'" shadow-inner
          :audit-logs="auditLogs"
          :audit-total="auditTotal"
          :is-refreshing="isAuditRefreshing"
          @refresh="handleAuditRefresh"
        />

        <!-- 标签页 8. 用户管理（仅管理员） -->
        <UserManagementTab 
          v-else-if="activeTab === 'users' && currentUser && currentUser.role === '超级管理员'"
          :current-user="currentUser"
        />

        <!-- 标签页 9. 数据源健康 -->
        <SourceHealthTab 
          v-else-if="activeTab === 'source_health'"
          :current-role="currentRole"
          :operator-name="operatorName"
          :monitor-sources="searchConfig.monitorSources || []"
        />

        <!-- 标签页 10. 推送配置 -->
        <PushConfigTab 
          v-else-if="activeTab === 'push_config'"
          :current-role="currentRole"
          :operator-name="operatorName"
        />

        <!-- 标签页 11. 客户与项目 -->
        <CustomersTab 
          v-else-if="activeTab === 'customers'"
          :current-role="currentRole"
          :operator-name="operatorName"
        />

      </main>

    </div>

    <!-- 手动输入系统弹窗 -->
    <AddLeadModal 
      v-if="showAddLeadModal"
      @close="showAddLeadModal = false"
      @submit="handleCreateManualLead"
    />

    <!-- 退出登录确认弹窗 -->
    <div v-if="showLogoutModal" class="fixed inset-0 z-[90] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4" @click.self="showLogoutModal = false">
      <div class="bg-white rounded-2xl max-w-sm w-full p-6 shadow-xl border border-gray-200 text-left">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 rounded-full bg-rose-500/15 flex items-center justify-center shrink-0">
            <LogOut class="h-5 w-5 text-rose-500" />
          </div>
          <div>
            <h3 class="text-base font-bold text-gray-900">确认退出登录？</h3>
            <p class="text-xs text-gray-500 mt-0.5">退出后需要重新登录才能继续使用</p>
          </div>
        </div>
        <div class="flex gap-2.5 justify-end">
          <button
            @click="showLogoutModal = false"
            class="bg-gray-200 hover:bg-gray-300 text-gray-700 text-xs font-semibold px-4 py-2 rounded-xl transition"
          >
            取消
          </button>
          <button
            @click="confirmLogout"
            class="bg-rose-600 hover:bg-rose-500 text-white text-xs font-semibold px-4 py-2 rounded-xl transition"
          >
            确认退出
          </button>
        </div>
      </div>
    </div>

    <!-- Toast 通知 -->
    <Transition name="toast">
      <div v-if="toast" :class="[
        'fixed top-6 left-1/2 -translate-x-1/2 z-[100] px-5 py-3 rounded-xl shadow-lg text-sm font-medium border max-w-md',
        toast.type === 'success' ? 'bg-emerald-50 border-emerald-200 text-emerald-800' : 
        toast.type === 'error' ? 'bg-red-50 border-red-200 text-red-800' : 
        'bg-blue-50 border-blue-200 text-blue-800'
      ]">
        {{ toast.message }}
      </div>
    </Transition>

    <!-- 全局居中二次确认弹窗 -->
    <div v-if="confirmDialog" class="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4" @click.self="closeConfirm(false)">
      <div class="bg-white rounded-2xl shadow-2xl border border-slate-200 w-full max-w-sm overflow-hidden">
        <div class="px-5 py-4 border-b border-slate-100 flex items-center justify-between">
          <h4 class="text-sm font-bold text-slate-800">{{ confirmDialog.title }}</h4>
          <button @click="closeConfirm(false)" class="text-slate-400 hover:text-slate-600 text-lg leading-none">&times;</button>
        </div>
        <div class="px-5 py-5 text-sm text-slate-600 leading-relaxed">{{ confirmDialog.message }}</div>
        <div class="px-5 pb-5 flex justify-end gap-2">
          <button
            @click="closeConfirm(false)"
            class="px-4 py-2 text-xs text-slate-500 hover:text-slate-700 border border-slate-300 rounded-lg transition cursor-pointer"
          >
            取消
          </button>
          <button
            @click="closeConfirm(true)"
            class="px-4 py-2 text-xs text-white font-semibold bg-blue-600 hover:bg-blue-500 rounded-lg transition cursor-pointer"
          >
            确定
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<style>
.toast-enter-active, .toast-leave-active { transition: all 0.3s ease; }
.toast-enter-from, .toast-leave-to { opacity: 0; transform: translateY(-10px); }
.light-gray-ui {
  background: linear-gradient(180deg, #eef2f7 0%, #e9eef5 100%) !important;
  color: #334155 !important;
}

body, html {
  background: #eef2f7 !important;
}

.light-gray-ui > .w-64 {
  background: #e2e8f0 !important;
  border-right-color: #cbd5e1 !important;
}

.light-gray-ui > .flex-1 {
  background: #edf2f7 !important;
}

.light-gray-ui [class*="bg-slate-95"],
.light-gray-ui [class*="bg-slate-9"],
.light-gray-ui [class*="bg-slate-8"] {
  background-color: #f8fafc !important;
}

.light-gray-ui [class*="bg-slate-7"] {
  background-color: #e8edf5 !important;
}

.light-gray-ui .hover\:bg-slate-700:hover {
  background-color: #dbe4f1 !important;
}

.light-gray-ui [class*="border-slate-"] {
  border-color: #d4dce8 !important;
}

/* 浅色主题：标题与正文对比度 */
.light-gray-ui h1,
.light-gray-ui h2,
.light-gray-ui h3,
.light-gray-ui h4,
.light-gray-ui h5,
.light-gray-ui h6 {
  color: #0f172a !important;
}

.light-gray-ui [class*="text-slate-1"],
.light-gray-ui [class*="text-slate-2"] {
  color: #1e293b !important;
}

.light-gray-ui [class*="text-slate-3"] {
  color: #334155 !important;
}

.light-gray-ui [class*="text-slate-4"],
.light-gray-ui [class*="text-slate-5"] {
  color: #475569 !important;
}

.light-gray-ui [class*="text-slate-6"] {
  color: #64748b !important;
}

.light-gray-ui [class*="text-slate-9"] {
  color: #0f172a !important;
}

/* 白字在浅色背景上不可见 → 改深色；有色按钮保留白字 */
.light-gray-ui .text-white {
  color: #1e293b !important;
}

.light-gray-ui [class*="bg-cyan-5"],
.light-gray-ui [class*="bg-cyan-5"] *,
.light-gray-ui [class*="bg-cyan-6"],
.light-gray-ui [class*="bg-cyan-6"] *,
.light-gray-ui [class*="bg-blue-6"],
.light-gray-ui [class*="bg-blue-6"] *,
.light-gray-ui [class*="bg-emerald-6"],
.light-gray-ui [class*="bg-emerald-6"] *,
.light-gray-ui [class*="bg-amber-6"],
.light-gray-ui [class*="bg-amber-6"] *,
.light-gray-ui [class*="bg-rose-6"],
.light-gray-ui [class*="bg-rose-6"] *,
.light-gray-ui .soft-btn-primary,
.light-gray-ui .soft-btn-success,
.light-gray-ui .soft-btn-danger {
  color: #ffffff !important;
}

/* 渐变透明字修复 */
.light-gray-ui [class*="bg-clip-text"][class*="text-transparent"] {
  color: #0f172a !important;
  -webkit-text-fill-color: #0f172a !important;
  background-image: none !important;
}

/* 语义色在浅色背景上加深 */
.light-gray-ui [class*="text-cyan-"] {
  color: #1d4ed8 !important;
}

.light-gray-ui [class*="text-indigo-"] {
  color: #4338ca !important;
}

.light-gray-ui [class*="text-purple-"] {
  color: #6d28d9 !important;
}

.light-gray-ui [class*="text-emerald-"] {
  color: #047857 !important;
}

.light-gray-ui [class*="text-amber-"] {
  color: #b45309 !important;
}

.light-gray-ui [class*="text-rose-"] {
  color: #be123c !important;
}

/* 关键词/标签胶囊：浅色底 + 深色字 */
.light-gray-ui [class*="bg-emerald-8"],
.light-gray-ui [class*="bg-emerald-9"] {
  background-color: #d1fae5 !important;
  border-color: #6ee7b7 !important;
}

.light-gray-ui [class*="bg-emerald-8"] [class*="text-emerald-"],
.light-gray-ui [class*="bg-emerald-9"] [class*="text-emerald-"] {
  color: #065f46 !important;
}

.light-gray-ui [class*="bg-rose-8"],
.light-gray-ui [class*="bg-rose-9"] {
  background-color: #ffe4e6 !important;
  border-color: #fda4af !important;
}

.light-gray-ui [class*="bg-rose-8"] [class*="text-rose-"],
.light-gray-ui [class*="bg-rose-9"] [class*="text-rose-"] {
  color: #9f1239 !important;
}

.light-gray-ui [class*="bg-cyan-9"] {
  background-color: #e0f2fe !important;
  border-color: #7dd3fc !important;
}

.light-gray-ui [class*="bg-cyan-9"] [class*="text-cyan-"] {
  color: #0369a1 !important;
}

/* 状态色半透明底（仅匹配徽章，避免误伤装饰光晕 bg-cyan-500/[0.03] 等） */
.light-gray-ui [class*="bg-cyan-500/1"],
.light-gray-ui [class*="bg-cyan-500/2"],
.light-gray-ui [class*="bg-cyan-500/5"],
.light-gray-ui [class*="bg-emerald-500/1"],
.light-gray-ui [class*="bg-emerald-500/2"],
.light-gray-ui [class*="bg-emerald-500/5"],
.light-gray-ui [class*="bg-amber-500/1"],
.light-gray-ui [class*="bg-amber-500/2"],
.light-gray-ui [class*="bg-amber-500/5"],
.light-gray-ui [class*="bg-rose-500/1"],
.light-gray-ui [class*="bg-rose-500/2"],
.light-gray-ui [class*="bg-rose-500/5"],
.light-gray-ui [class*="bg-purple-500/1"],
.light-gray-ui [class*="bg-purple-500/2"],
.light-gray-ui [class*="bg-purple-500/5"] {
  background-color: #e8eef7 !important;
}

.light-gray-ui .bg-cyan-500 {
  background-color: #2563eb !important;
}

/* 选中菜单项：蓝底 + 白色文字（深浅主题一致） */
.light-gray-ui .menu-item-active {
  color: #ffffff !important;
}

.light-gray-ui .hover\:bg-slate-900:hover,
.light-gray-ui .hover\:bg-slate-800:hover {
  background-color: #dbe4f1 !important;
}

.light-gray-ui .hover\:text-slate-200:hover {
  color: #1e293b !important;
}

.light-gray-ui [class*="hover:text-cyan-3"]:hover,
.light-gray-ui [class*="hover:text-cyan-4"]:hover {
  color: #1e40af !important;
}

.light-gray-ui input[type="file"]::file-selector-button {
  color: #ffffff !important;
  background-color: #2563eb !important;
}

/* 弹窗遮罩保持半透明深色 */
.light-gray-ui .fixed.inset-0[class*="bg-slate-"],
.light-gray-ui .fixed.inset-0[class*="bg-black"] {
  background-color: rgba(15, 23, 42, 0.55) !important;
}

.light-gray-ui .fixed.inset-0 [class*="bg-slate-9"]:not([class*="inset-0"]) {
  background-color: #ffffff !important;
  border-color: #cbd5e1 !important;
  color: #1e293b !important;
}

.light-gray-ui .shadow-lg,
.light-gray-ui .shadow-xl {
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.08) !important;
}

.light-gray-ui input,
.light-gray-ui select,
.light-gray-ui textarea {
  background-color: #f3f6fb !important;
  color: #334155 !important;
  border-color: #bfccdd !important;
}

.light-gray-ui input::placeholder,
.light-gray-ui textarea::placeholder {
  color: #94a3b8 !important;
}

.light-gray-ui .focus\:ring-cyan-500:focus,
.light-gray-ui .focus\:border-cyan-500:focus {
  --tw-ring-color: #3b82f6 !important;
  border-color: #3b82f6 !important;
}

.light-gray-ui .soft-panel-strong {
  background: linear-gradient(180deg, #e9eef7 0%, #e3eaf4 100%) !important;
  border-color: #c4d0e0 !important;
}

.light-gray-ui .soft-panel {
  background: #eef3f9 !important;
  border-color: #cad5e5 !important;
}

.light-gray-ui .soft-panel-inner {
  background: #e6edf6 !important;
  border-color: #c4d1e4 !important;
}

.light-gray-ui .soft-panel-muted {
  background: #e8eef7 !important;
  border-color: #ccd8e8 !important;
}

.light-gray-ui .soft-input {
  background: #f0f4fa !important;
  border-color: #b8c7da !important;
  color: #1f2937 !important;
}

.light-gray-ui .soft-btn {
  background: #d8e1ee !important;
  border-color: #afbed4 !important;
  color: #1f2937 !important;
}

.light-gray-ui .soft-btn:hover {
  background: #ccd8e9 !important;
}

.light-gray-ui .soft-btn-primary {
  background: #2563eb !important;
  color: #ffffff !important;
  border: 1px solid #1d4ed8 !important;
  box-shadow: 0 6px 14px rgba(37, 99, 235, 0.22) !important;
}

.light-gray-ui .soft-btn-primary:hover {
  background: #1d4ed8 !important;
}

.light-gray-ui .soft-btn-success {
  background: #0f766e !important;
  color: #ffffff !important;
  border: 1px solid #0f766e !important;
}

.light-gray-ui .soft-btn-success:hover {
  background: #0d9488 !important;
}

.light-gray-ui .soft-btn-danger {
  background: #9f1239 !important;
  color: #ffffff !important;
  border: 1px solid #881337 !important;
}

.light-gray-ui .soft-btn-danger:hover {
  background: #be123c !important;
}

/* 5维打分滑块：自绘轨道（带填充进度）+ 圆润滑钮 */
.score-slider {
  -webkit-appearance: none;
  appearance: none;
  width: 100%;
  background: transparent;
  outline: none;
  cursor: pointer;
}
.score-slider::-webkit-slider-runnable-track {
  height: 6px;
  border-radius: 9999px;
  background: linear-gradient(90deg, #0ea5e9 var(--fill, 50%), #e2e8f0 var(--fill, 50%));
}
.score-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 16px;
  height: 16px;
  margin-top: -5px;
  border-radius: 9999px;
  background: #ffffff;
  border: 2px solid #0ea5e9;
  box-shadow: 0 2px 6px rgba(15, 23, 42, 0.25);
  cursor: pointer;
}
.score-slider::-webkit-slider-thumb:hover {
  background: #e0f2fe;
}
.score-slider::-moz-range-track {
  height: 6px;
  border-radius: 9999px;
  background: linear-gradient(90deg, #0ea5e9 var(--fill, 50%), #e2e8f0 var(--fill, 50%));
}
.score-slider::-moz-range-thumb {
  width: 16px;
  height: 16px;
  border-radius: 9999px;
  background: #ffffff;
  border: 2px solid #0ea5e9;
  box-shadow: 0 2px 6px rgba(15, 23, 42, 0.25);
  cursor: pointer;
}
.score-slider::-moz-range-thumb:hover {
  background: #e0f2fe;
}

/* 全局字体 — 微软雅黑 */
body, .light-gray-ui, .light-gray-ui * {
  font-family: 'Microsoft YaHei', '微软雅黑', 'PingFang SC', 'Helvetica Neue', Arial, sans-serif !important;
}
</style>
