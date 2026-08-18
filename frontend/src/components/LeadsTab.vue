<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount, defineProps, defineEmits } from 'vue';
import {
  Building2,
  MapPin,
  Layers,
  Sparkles,
  Sliders,
  Search,
  Filter,
  X,
  Trash2,
  Plus,
  CheckCircle,
  Clock,
  AlertTriangle,
  ChevronRight,
  Database,
  AlertCircle,
  RefreshCw,
  Activity,
  ChevronDown,
  ExternalLink,
  ImageIcon
} from 'lucide-vue-next';
import { Lead, ScoringRule, SearchConfig, User, LeadActivity } from '../types';
import { getLeadProvince, getDisplayRegion } from '../services/provinceUtil';

const props = defineProps<{
  leads: Lead[];
  selectedLead: Lead | null;
  searchConfig: SearchConfig;
  searchConfigStats: {
    keywordCount: number;
    matchedLeadsCount: number;
  };
  isMining: boolean;
  miningStatus: string;
  lastCrawlTimestamp: string;
  currentRole: string;
  operatorName: string;
  scoringRule: ScoringRule;
  systemUsers?: User[];
  leadActivities: LeadActivity[];
}>();

const emit = defineEmits<{
  (e: 'select-lead', lead: Lead | null): void;
  (e: 'open-add-modal'): void;
  (e: 'trigger-mining'): void;
  (e: 'status-change', payload: { leadId: string; status: Lead['status']; returnReason?: string }): void;
  (e: 'assign-person', payload: { leadId: string; person: string }): void;
  (e: 'save-notes', payload: { leadId: string; notes: string }): void;
  (e: 'update-contact', payload: { leadId: string; contactName: string; contactPhone: string }): void;
  (e: 'delete-lead', leadId: string): void;
  (e: 'switch-tab', tabName: 'research' | 'competitors'): void;
  (e: 'add-activity', payload: { leadId: string; content: string; activityType?: string }): Promise<boolean> | void;
  (e: 'convert-lead', leadId: string): void;
  (e: 'import-leads', file: File, duplicateAction: 'skip' | 'overwrite'): void;
  (e: 'download-template'): void;
  (e: 'toggle-favorite', leadId: string): void;
}>();

const editContactName = ref('');
const editContactPhone = ref('');
const editPhoneError = ref('');

watch(
    () => props.selectedLead,
    (lead) => {
      const name = lead?.contactName || '';
      const phone = lead?.contactPhone || '';
      editContactName.value = name === '无权查看' ? '' : name;
      editContactPhone.value = phone === '无权查看' || phone === '未登记' ? '' : phone;
      editPhoneError.value = ''; // 切换线索时清空校验错误提示
    },
    { immediate: true },
);

// 本地筛选状态
const searchQuery = ref('');
const selectedGrade = ref<'ALL' | 'A' | 'B' | 'C'>('ALL');
const selectedStatus = ref<'ALL' | Lead['status']>('ALL');
const selectedRegion = ref<string>('ALL');
const showFavoritesOnly = ref(false);
const crawlTimeStart = ref('');
const crawlTimeEnd = ref('');
const showFilters = ref(false);

// 重置全部：清空外部搜索与所有高级筛选条件
const resetAllFilters = () => {
  searchQuery.value = '';
  selectedGrade.value = 'ALL';
  selectedStatus.value = 'ALL';
  selectedRegion.value = 'ALL';
  showFavoritesOnly.value = false;
  crawlTimeStart.value = '';
  crawlTimeEnd.value = '';
};

// 高级筛选：点击外部区域自动收起
const filterPanelRef = ref<HTMLElement | null>(null);
const filterButtonRef = ref<HTMLElement | null>(null);
const handleClickOutside = (e: MouseEvent) => {
  if (!showFilters.value) return;
  const target = e.target as Node;
  if (filterPanelRef.value?.contains(target) || filterButtonRef.value?.contains(target)) return;
  showFilters.value = false;
};
onMounted(() => document.addEventListener('click', handleClickOutside));
onBeforeUnmount(() => document.removeEventListener('click', handleClickOutside));

const clearCrawlTimeFilter = () => {
  crawlTimeStart.value = '';
  crawlTimeEnd.value = '';
};

type ScoreDimension = {
  label: string;
  score: number;
  weight: number;
  weighted: number;
  sharePercent: number;
};

const scoreBreakdown = computed<ScoreDimension[]>(() => {
  const lead = props.selectedLead;
  if (!lead) return [];

  const rule = props.scoringRule;
  const dimensions = [
    { label: '项目预算分', score: lead.budgetScore, weight: rule.budgetWeight },
    { label: '需求匹配度', score: lead.matchScore, weight: rule.matchWeight },
    { label: '项目阶段分', score: lead.stageScore, weight: rule.stageWeight },
    { label: '客户资质', score: lead.qualificationScore, weight: rule.qualificationWeight },
    { label: '地域匹配分', score: lead.regionScore, weight: rule.regionWeight },
  ];

  const items = dimensions.map((dim) => ({
    ...dim,
    weighted: Math.round(dim.score * dim.weight) / 100,
  }));
  const total = lead.totalScore > 0
      ? lead.totalScore
      : items.reduce((sum, item) => sum + item.weighted, 0);

  return items.map((item) => ({
    ...item,
    sharePercent: total > 0 ? Math.round((item.weighted / total) * 1000) / 10 : 0,
  }));
});

const scoreBreakdownWithFlag = computed(() => {
  const items = [...scoreBreakdown.value];
  if (items.length === 0) return items;
  const max = Math.max(...items.map((i) => i.score));
  const min = Math.min(...items.map((i) => i.score));
  return items.map((item) => ({
    ...item,
    isMax: item.score === max,
    isMin: item.score === min,
  }));
});

// 跟进生命周期下拉：仅保留当前状态 + 可合法流转的目标状态（禁用的不展示）
const availableStatusOptions = computed(() => {
  const status = props.selectedLead?.status;
  if (!status) return [];
  if (status === '已转化') return [];
  const canFinalize = props.currentRole === '超级管理员' || props.currentRole === '商务负责人';
  const list: string[] = [status];
  switch (status) {
    case '待分级':
      list.push('待分配');
      break;
    case '待分配':
      // 必须先指派跟进人才能进入跟进中，否则该项不可选
      if (props.selectedLead?.followUpPerson) list.push('跟进中');
      break;
    case '跟进中':
      list.push('已转化', '已无效', '已流失');
      break;
    case '已无效':
    case '已流失':
      // 超级管理员 / 商务负责人可将已无效/已流失退回跟进中
      if (props.currentRole === '超级管理员' || props.currentRole === '商务负责人') list.push('跟进中');
      break;
  }
  // 超管 / 商务负责人：任意阶段都能直接流转为 已无效 / 已流失
  if (canFinalize && status !== '已无效' && status !== '已流失') {
    if (!list.includes('已无效')) list.push('已无效');
    if (!list.includes('已流失')) list.push('已流失');
  }
  return list;
});

const maskPhone = (phone: string | undefined): string => {
  if (!phone) return '未登记';
  if (props.currentRole === '超级管理员' || props.currentRole === '商务负责人' || props.currentRole === '商务专员') {
    return phone;
  }
  return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2');
};

const VIEWED_KEY = 'trae_viewed_leads';
const viewedLeadIds = ref<Set<string>>(new Set(JSON.parse(localStorage.getItem(VIEWED_KEY) || '[]')));

const saveViewed = () => {
  localStorage.setItem(VIEWED_KEY, JSON.stringify([...viewedLeadIds.value]));
};

const markAsViewed = (lead: Lead) => {
  viewedLeadIds.value = new Set([...viewedLeadIds.value, lead.id]);
  saveViewed();
  emit('select-lead', lead);
};

const isNewlyCrawled = (lead: Lead): boolean => {
  if (!props.lastCrawlTimestamp || !lead.crawlTime) return false;
  if (viewedLeadIds.value.has(lead.id)) return false;
  const t = lead.crawlTime.replace('T', ' ').replace(/\+.*$/, '');
  return t >= props.lastCrawlTimestamp;
};

const relativeTime = (dt?: string): string => {
  if (!dt) return '';
  const t = new Date(dt.includes('T') ? dt : dt.replace(' ', 'T').replace(/\+.*$/, ''));
  if (isNaN(t.getTime())) return dt.replace('T', ' ').replace(/\+.*$/, '');
  const m = Math.floor((Date.now() - t.getTime()) / 60000);
  if (m < 1) return '刚刚';
  if (m < 60) return `${m} 分钟前`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h} 小时前`;
  const d = Math.floor(h / 24);
  if (d < 30) return `${d} 天前`;
  return dt.replace('T', ' ').replace(/\+.*$/, '').slice(0, 10);
};

const regionOptions = computed(() => {
  const set = new Set<string>();
  (props.leads || []).forEach(l => {
    const p = getLeadProvince(l);
    if (p) set.add(p);
  });
  return Array.from(set).sort((a, b) => a.localeCompare(b, 'zh'));
});

const filteredLeads = computed(() => {
  return (props.leads || []).filter(lead => {
    if (!lead || !lead.title) return false;
    const cleanSearch = searchQuery.value.toLowerCase();
    const matchesSearch =
        lead.title.toLowerCase().includes(cleanSearch) ||
        lead.company.toLowerCase().includes(cleanSearch) ||
        lead.requirements.toLowerCase().includes(cleanSearch) ||
        (lead.industry && lead.industry.toLowerCase().includes(cleanSearch));

    const matchesGrade = selectedGrade.value === 'ALL' ? true : lead.grade === selectedGrade.value;
    const matchesStatus = selectedStatus.value === 'ALL' ? true : lead.status === selectedStatus.value;
    const matchesRegion = selectedRegion.value === 'ALL' ? true : getLeadProvince(lead) === selectedRegion.value;
    const matchesFavorite = !showFavoritesOnly.value || lead.isFavorite === true;
    const matchesCrawlTime = (
        (!crawlTimeStart.value || (lead.crawlTime && lead.crawlTime.replace('T', ' ') >= crawlTimeStart.value)) &&
        (!crawlTimeEnd.value || (lead.crawlTime && lead.crawlTime.replace('T', ' ') <= crawlTimeEnd.value + ' 23:59:59'))
    );

    return matchesSearch && matchesGrade && matchesStatus && matchesRegion && matchesFavorite && matchesCrawlTime;
  });
});

const assignableUsers = computed(() => {
  if (props.systemUsers && props.systemUsers.length > 0) {
    return props.systemUsers.filter(u => u.role === '商务专员');
  }
  return [
    { name: '前端突破专员王小二', role: '商务专员' }
  ];
});

const showReturnModal = ref(false);
const returnReasonInput = ref('');
const newActivityContent = ref('');
const pendingImages = ref<{ url: string; name: string }[]>([]);
const uploadingImages = ref(false);
const imageInput = ref<HTMLInputElement | null>(null);
const showImportModal = ref(false);
const showOperationModal = ref(false);
const showAiPanel = ref(true);
const showFollowPanel = ref(true);
const importFile = ref<File | null>(null);
const importDuplicateAction = ref<'skip' | 'overwrite'>('skip');
const importLoading = ref(false);

const handleUploadImage = async (event: Event) => {
  const input = event.target as HTMLInputElement;
  const files = Array.from(input.files || []);
  if (files.length === 0) return;
  input.value = '';
  uploadingImages.value = true;
  try {
    for (const file of files) {
      const formData = new FormData();
      formData.append('file', file);
      const res = await fetch('/api/upload/image', {
        method: 'POST',
        body: formData,
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        alert(err.detail || '图片上传失败');
        continue;
      }
      const data = await res.json();
      pendingImages.value.push({ url: data.url, name: file.name });
    }
  } catch (e) {
    alert('图片上传失败，请检查 MinIO 服务是否可用');
  } finally {
    uploadingImages.value = false;
  }
};

const removePendingImage = (idx: number) => {
  pendingImages.value.splice(idx, 1);
};

const handleStatusSelectChange = (event: Event) => {
  const newStatus = (event.target as HTMLSelectElement).value as Lead['status'];
  if (!props.selectedLead) return;

  const oldStatus = props.selectedLead.status;
  if ((oldStatus === '已无效' || oldStatus === '已流失') && newStatus === '跟进中') {
    if (props.currentRole !== '超级管理员') {
      alert('只有超级管理员有权退回已无效或已流失的线索');
      (event.target as HTMLSelectElement).value = oldStatus;
      return;
    }
    showReturnModal.value = true;
    returnReasonInput.value = '';
    return;
  }

  emit('status-change', { leadId: props.selectedLead.id, status: newStatus });
};

const confirmReturn = () => {
  if (!props.selectedLead) return;
  if (!returnReasonInput.value.trim()) {
    alert('请填写退回原因');
    return;
  }
  emit('status-change', {
    leadId: props.selectedLead.id,
    status: '跟进中',
    returnReason: returnReasonInput.value.trim()
  });
  showReturnModal.value = false;
};

const cancelReturn = () => {
  showReturnModal.value = false;
  returnReasonInput.value = '';
};

const submitActivity = async () => {
  if (!props.selectedLead || (!newActivityContent.value.trim() && pendingImages.value.length === 0)) return;
  let content = newActivityContent.value.trim();
  for (const img of pendingImages.value) {
    content += `\n![]( ${img.url} )`;
  }
  const ok = await emit('add-activity', {
    leadId: props.selectedLead.id,
    content: content,
    activityType: 'comment',
  });
  if (ok !== false) {
    newActivityContent.value = '';
    pendingImages.value = [];
  }
};

const commentActivities = computed(() => {
  return props.leadActivities
      .filter(a => a.activityType === 'comment')
      .map(a => ({ ...a, createdAt: (a.createdAt || '').replace('T', ' ').replace(/\+.*$/, '') }))
      .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
});

const cleanRequirements = computed(() => {
  const raw = props.selectedLead?.requirements || '';
  const cleaned = raw.replace(/\n{1,2}\s*原文链接\s*[:：]\s*(?:https?:\/\/|www\.)\S+/gi, '').trim();
  return cleaned || '暂无详细需求描述';
});

const extractImages = (content: string): string[] => {
  const urls: string[] = [];
  const re = /!\[\s*\]\(\s*(.*?)\s*\)/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(content || '')) !== null) {
    urls.push(m[1].trim());
  }
  return urls;
};

const stripImageMarkdown = (content: string): string => {
  return (content || '').replace(/!\[\s*\]\(\s*[^)]*\s*\)/g, '').trim();
};

const viewerUrl = ref<string | null>(null);

const allActivities = computed(() => {
  const items: (LeadActivity & { isVirtual?: boolean })[] = [];
  for (const a of props.leadActivities) {
    if (a.activityType === 'comment') continue;
    items.push({
      ...a,
      isVirtual: false,
      createdAt: (a.createdAt || '').replace('T', ' ').replace(/\+.*$/, ''),
    });
  }
  // 入库活动：按线索来源区分（爬虫/导入/人工录入）
  const src = props.selectedLead?.source || 'crawler';
  const srcLabel = src === 'manual'
      ? '✍️ 人工录入线索'
      : src === 'import'
          ? '📥 批量导入线索'
          : '🤖 AI 爬虫自动抓取入库';
  const entryTime = (props.selectedLead?.crawlTime || props.selectedLead?.createdAt || '')
      .replace('T', ' ').replace(/\+.*$/, '');
  if (entryTime) {
    items.push({
      id: 'crawl-' + props.selectedLead.id,
      leadId: props.selectedLead.id,
      activityType: 'system',
      content: srcLabel,
      operator: '系统',
      createdAt: entryTime,
      isVirtual: true,
    } as LeadActivity & { isVirtual?: boolean });
  }
  items.sort((a, b) => (a.createdAt || '').localeCompare(b.createdAt || ''));
  return items;
});

const statusCounts = computed(() => {
  const counts: Record<string, number> = {};
  for (const s of ['待分级', '待分配', '跟进中', '已转化', '已无效', '已流失']) {
    counts[s] = props.leads.filter(l => l.status === s).length;
  }
  return counts;
});

const statusConfig: Record<string, { color: string; bg: string }> = {
  '待分级': { color: 'text-cyan-400', bg: 'bg-cyan-500/15' },
  '待分配': { color: 'text-blue-400', bg: 'bg-blue-500/15' },
  '跟进中': { color: 'text-purple-400', bg: 'bg-purple-500/15' },
  '已转化': { color: 'text-emerald-400', bg: 'bg-emerald-500/15' },
  '已无效': { color: 'text-rose-400', bg: 'bg-rose-500/15' },
  '已流失': { color: 'text-amber-400', bg: 'bg-amber-500/15' },
};

const cardBorderColors: Record<string, string> = {
  '待分级': 'bg-cyan-500',
  '待分配': 'bg-blue-500',
  '跟进中': 'bg-purple-500',
  '已转化': 'bg-emerald-500',
  '已无效': 'bg-rose-500',
  '已流失': 'bg-amber-500',
};

// 重构后的右侧对接卡片带有高级感外边框与光晕配置
const statusBorderColors: Record<string, string> = {
  '待分级': 'border-cyan-500/50 ring-1 ring-cyan-500/10 shadow-lg shadow-cyan-900/10',
  '待分配': 'border-blue-500/50 ring-1 ring-blue-500/10 shadow-lg shadow-blue-900/10',
  '跟进中': 'border-purple-500/50 ring-1 ring-purple-500/10 shadow-lg shadow-purple-900/10',
  '已转化': 'border-emerald-500/50 ring-1 ring-emerald-500/10 shadow-lg shadow-emerald-900/10',
  '已无效': 'border-rose-500/50 ring-1 ring-rose-500/10 shadow-lg shadow-rose-900/10',
  '已流失': 'border-amber-500/50 ring-1 ring-amber-500/10 shadow-lg shadow-amber-900/10',
};
const contactCardBorderClass = computed(() => statusBorderColors[props.selectedLead?.status || ''] || 'border-slate-700/50 shadow-md');

const canManage = computed(() => props.currentRole === '超级管理员' || props.currentRole === '商务负责人');
const canEditContact = computed(() => props.currentRole === '超级管理员' || props.currentRole === '商务负责人');

const contactDirty = computed(() => {
  const lead = props.selectedLead;
  if (!lead) return false;
  const savedName = lead.contactName === '无权查看' ? '' : (lead.contactName || '');
  const savedPhone = lead.contactPhone === '无权查看' ? '' : (lead.contactPhone || '');
  return editContactName.value.trim() !== savedName.trim()
      || editContactPhone.value.trim() !== savedPhone.trim();
});

const saveContact = () => {
  if (!props.selectedLead || !canEditContact.value || !contactDirty.value) return;
  editPhoneError.value = validatePhone(editContactPhone.value.trim());
  if (editPhoneError.value) return;
  emit('update-contact', {
    leadId: props.selectedLead.id,
    contactName: editContactName.value.trim(),
    contactPhone: editContactPhone.value.trim(),
  });
};

// 手机号 / 座机号校验（选填字段）：手机 1[3-9] 开头 11 位，座机 0+区号3-4位+号码7-8位，可带分机
const validatePhone = (p: string) => {
  if (!p) return ''; // 选填，为空不校验
  const mobile = /^1[3-9]\d{9}$/;
  const landline = /^0\d{2,3}-?\d{7,8}(-\d{1,5})?$/;
  if (mobile.test(p) || landline.test(p)) return '';
  return '手机号需为 11 位（如 13800138000），座机号格式如 0713-1234567';
};

defineExpose({
  closeImportModal() {
    showImportModal.value = false;
    importLoading.value = false;
    importFile.value = null;
  },
});
</script>

<template>
  <!-- 全局立体深色底盘包裹 -->
  <div class="flex-1 flex overflow-hidden bg-slate-950 p-3 sm:p-4 gap-3 sm:gap-4">

    <!-- 左侧主控卡片：线索列表与搜索筛选 -->
    <div class="w-[27rem] rounded-2xl border border-slate-800/80 shadow-2xl flex flex-col bg-slate-900 shrink-0 relative overflow-hidden">

      <!-- 头部：搜索与筛选操作。提高 z-index 避免被下方新角标遮盖导致穿透 -->
      <div class="p-4 border-b border-slate-800/80 bg-slate-900 space-y-3 shrink-0 relative z-40">
        <!-- 页面标题行：标题 + 主/次操作按钮 -->
        <div class="flex items-center justify-between gap-2">
          <div class="flex items-center gap-2 min-w-0">
            <span class="text-sm font-extrabold text-slate-100 tracking-wide truncate">监测线索库</span>
            <span class="shrink-0 text-[10px] font-medium text-slate-500 bg-slate-800 border border-slate-700/80 rounded-full px-2.5 py-0.5">{{ filteredLeads.length }} / {{ props.leads.length }} 条</span>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <button
                @click="emit('open-add-modal')"
                class="bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white text-xs font-semibold px-3 py-2 rounded-lg flex items-center gap-1.5 shadow-md shadow-blue-900/30 transition disabled:opacity-50"
            >
              <Plus class="h-3.5 w-3.5" />
              <span>手动录入</span>
            </button>
            <button
                @click="showImportModal = true"
                class="bg-slate-800/80 hover:bg-slate-700 active:bg-slate-900 text-slate-300 text-xs font-semibold px-3 py-2 rounded-lg flex items-center gap-1.5 border border-slate-700/60 shadow-sm transition"
            >
              <Database class="h-3.5 w-3.5" />
              <span>Excel导入</span>
            </button>
          </div>
        </div>

        <!-- 下凹阴影搜索框 -->
        <div class="relative">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 h-4 w-4 pointer-events-none" />
          <input
              type="text"
              placeholder="检索项目、企业、核心需求..."
              v-model="searchQuery"
              class="bg-slate-900/80 shadow-inner text-xs w-full text-slate-100 pl-9 pr-8 py-2.5 rounded-xl border border-slate-700/60 focus:outline-none focus:border-cyan-500/60 focus:ring-1 focus:ring-cyan-500/30 placeholder-slate-500 transition"
          />
          <button
              v-if="searchQuery"
              @click="searchQuery = ''"
              class="absolute right-2 top-1/2 -translate-y-1/2 h-5 w-5 flex items-center justify-center rounded-full text-slate-400 hover:text-slate-100 hover:bg-slate-700/70 transition"
              title="一键清空"
          >
            <X class="h-3.5 w-3.5" />
          </button>
        </div>

        <!-- 高级筛选 -->
        <div class="relative">
          <button
              ref="filterButtonRef"
              @click="showFilters = !showFilters"
              class="w-full text-xs text-slate-400 hover:text-slate-200 flex items-center justify-between py-2 px-3 rounded-xl border border-slate-700/60 bg-slate-800/40 shadow-sm transition"
          >
            <span class="font-medium">高级筛选</span>
            <ChevronDown :class="['h-3.5 w-3.5 transition', showFilters ? 'rotate-180' : '']" />
          </button>

          <!-- 悬浮弹窗卡片 (改为纯色不透明, 提高层级) -->
          <div v-if="showFilters" ref="filterPanelRef" class="absolute left-0 right-0 top-full mt-3 z-50 bg-slate-800 border border-slate-600/80 rounded-2xl p-4 space-y-4 shadow-[0_10px_40px_rgba(0,0,0,0.8)]">
            <div class="flex items-center justify-between border-b border-slate-700/50 pb-2">
              <span class="text-xs font-bold text-slate-200">高级筛选条件</span>
              <div class="flex items-center gap-2">
                <button @click="resetAllFilters" class="text-[10px] text-amber-400 hover:text-amber-300 transition">重置全部</button>
                <button @click="showFilters = false" class="text-[10px] text-slate-400 hover:text-slate-200 transition">收起 ✕</button>
              </div>
            </div>

            <div class="grid grid-cols-3 gap-3">
              <div>
                <span class="text-[10px] text-slate-400 block mb-1.5 font-medium">省份</span>
                <select v-model="selectedRegion" class="bg-slate-900/60 shadow-inner text-xs w-full text-slate-300 py-1.5 px-1.5 rounded-lg border border-slate-700/60 focus:outline-none focus:ring-1 focus:ring-cyan-500/30">
                  <option value="ALL">全部</option>
                  <option v-for="r in regionOptions" :key="r" :value="r">{{ r }}</option>
                </select>
              </div>
              <div>
                <span class="text-[10px] text-slate-400 block mb-1.5 font-medium">分级</span>
                <select v-model="selectedGrade" class="bg-slate-900/60 shadow-inner text-xs w-full text-slate-300 py-1.5 px-1.5 rounded-lg border border-slate-700/60 focus:outline-none focus:ring-1 focus:ring-cyan-500/30">
                  <option value="ALL">全部</option>
                  <option value="A">A 级</option>
                  <option value="B">B 级</option>
                  <option value="C">C 级</option>
                </select>
              </div>
              <div>
                <span class="text-[10px] text-slate-400 block mb-1.5 font-medium">状态</span>
                <select v-model="selectedStatus" class="bg-slate-900/60 shadow-inner text-xs w-full text-slate-300 py-1.5 px-1.5 rounded-lg border border-slate-700/60 focus:outline-none focus:ring-1 focus:ring-cyan-500/30">
                  <option value="ALL">全部</option>
                  <option v-for="s in ['待分级', '待分配', '跟进中', '已转化', '已无效', '已流失']" :key="s" :value="s">{{ s }}</option>
                </select>
              </div>
            </div>

            <div>
              <div class="flex items-center justify-between mb-1.5">
                <span class="text-[10px] text-slate-400 font-medium">抓取时间</span>
                <button v-if="crawlTimeStart || crawlTimeEnd" @click="clearCrawlTimeFilter" class="text-[10px] text-slate-400 hover:text-slate-200 transition">清除</button>
              </div>
              <div class="flex items-center gap-2">
                <input v-model="crawlTimeStart" type="date" @click="(e) => (e.target as any).showPicker?.()" class="cursor-pointer bg-slate-900/60 shadow-inner text-xs text-slate-300 py-1.5 px-2 rounded-lg border border-slate-700/60 focus:outline-none focus:ring-1 focus:ring-cyan-500/30 w-full" />
                <span class="text-xs text-slate-500">~</span>
                <input v-model="crawlTimeEnd" type="date" @click="(e) => (e.target as any).showPicker?.()" class="cursor-pointer bg-slate-900/60 shadow-inner text-xs text-slate-300 py-1.5 px-2 rounded-lg border border-slate-700/60 focus:outline-none focus:ring-1 focus:ring-cyan-500/30 w-full" />
              </div>
            </div>

            <button
                @click="showFavoritesOnly = !showFavoritesOnly"
                :class="[
                'w-full text-xs font-bold px-3 py-2 rounded-xl border transition flex items-center justify-center gap-1.5 shadow-sm',
                showFavoritesOnly
                  ? 'bg-amber-500/20 border-amber-500/40 text-amber-400 shadow-amber-900/20'
                  : 'bg-slate-900/60 border-slate-700/60 text-slate-400 hover:text-slate-200 hover:bg-slate-800'
              ]"
            >
              <span>{{ showFavoritesOnly ? '★ 取消筛选' : '☆ 只看收藏' }}</span>
            </button>
          </div>
        </div>
      </div>

      <!-- 网监监控 -->
      <div v-if="currentRole === '超级管理员' || currentRole === '商务负责人'" class="bg-slate-800/20 p-4 border-b border-slate-800/80 flex items-center justify-between gap-3 shrink-0">
        <div class="min-w-0">
          <span class="block text-xs font-bold text-slate-200">网监监控状态</span>
          <span class="block text-[11px] text-slate-500 font-mono truncate mt-0.5">{{ searchConfig.frequency }} / 关键字 {{ searchConfigStats.keywordCount }} 个 · 匹配 {{ searchConfigStats.matchedLeadsCount }} 条线索</span>
        </div>
        <button
            @click="emit('trigger-mining')"
            :disabled="isMining"
            class="shrink-0 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white text-xs font-semibold px-3 py-2 rounded-lg flex items-center gap-1.5 transition disabled:opacity-50 disabled:cursor-not-allowed shadow-md shadow-blue-900/30"
        >
          <RefreshCw :class="['h-3.5 w-3.5', isMining ? 'animate-spin text-amber-400' : '']" />
          <span>{{ isMining ? 'AI分析中' : 'AI定时抓取' }}</span>
        </button>
      </div>

      <!-- 列表主体区 (包含内边距以实现子卡片感) -->
      <div class="flex-1 overflow-y-auto overflow-x-hidden scrollbar-thin p-3 space-y-3">

        <!-- 加载与空状态 -->
        <div v-if="isMining" class="p-6 text-center space-y-3">
          <div class="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-cyan-400"></div>
          <p class="text-xs text-amber-400 font-mono animate-pulse">{{ miningStatus }}</p>
        </div>
        <div v-if="filteredLeads.length === 0 && !isMining && props.leads.length === 0" class="flex-1 flex flex-col items-center justify-center p-8 text-center mt-10">
          <div class="w-16 h-16 rounded-full bg-slate-800/50 border border-slate-700/50 flex items-center justify-center mb-4 shadow-sm">
            <AlertCircle class="h-8 w-8 text-slate-500" />
          </div>
          <p class="text-sm font-semibold text-slate-300 mb-1">暂无商务线索</p>
          <p class="text-xs text-slate-500 max-w-[200px]">点击上方「AI定时抓取」或「手动录入」开始构建您的商机库</p>
        </div>
        <div v-if="filteredLeads.length === 0 && !isMining && props.leads.length > 0" class="flex-1 flex flex-col items-center justify-center p-8 text-center mt-10">
          <Search class="h-10 w-10 text-slate-600 mb-3" />
          <p class="text-sm font-semibold text-slate-300 mb-1">无匹配结果</p>
          <p class="text-xs text-slate-500">尝试修改筛分条件或搜索关键词</p>
        </div>

        <!-- 独立卡片式线索项 -->
        <div
            v-for="lead in filteredLeads"
            :key="lead.id"
            @click="markAsViewed(lead)"
            :class="[
            'relative flex cursor-pointer transition-all border rounded-xl group overflow-hidden shadow-sm',
            selectedLead?.id === lead.id
              ? 'bg-blue-500/10 border-blue-500/50 shadow-md shadow-blue-900/20 ring-1 ring-blue-500/30'
              : 'bg-slate-800/30 border-slate-700/50 hover:bg-slate-800/60 hover:border-slate-600/60 hover:shadow-md'
          ]"
        >
          <!-- 绝对定位左侧高亮细条，不受 padding 影响 -->
          <div
              class="absolute left-0 top-0 bottom-0 transition-all z-0"
              :class="[
                cardBorderColors[lead.status] || 'bg-slate-700',
                selectedLead?.id === lead.id ? 'w-1.5' : 'w-1'
              ]"
          ></div>

          <!-- 左上角显眼新线索角标 -->
          <div
              v-if="isNewlyCrawled(lead)"
              class="absolute top-0 left-0 z-20 bg-gradient-to-br from-rose-500 to-orange-500 text-white text-[10px] font-black px-2 py-0.5 rounded-br-xl shadow-lg shadow-rose-900/50 animate-pulse border-b border-r border-rose-400/50 flex items-center gap-0.5"
          >
            <Sparkles class="h-2.5 w-2.5" />
            <span>新</span>
          </div>

          <div class="flex-1 p-3.5 pl-4 min-w-0 relative z-10">
            <!-- 第一行：收藏 + 项目名称 + 评分 -->
            <div class="flex items-center gap-1.5 mb-1.5">
              <button
                  @click.stop="emit('toggle-favorite', lead.id)"
                  :class="[
                  'shrink-0 w-5 h-5 flex items-center justify-center rounded transition text-sm leading-none',
                  lead.isFavorite ? 'text-amber-400 hover:text-amber-300' : 'text-slate-500 hover:text-slate-300'
                ]"
                  :title="lead.isFavorite ? '取消收藏' : '收藏'"
              >
                {{ lead.isFavorite ? '★' : '☆' }}
              </button>
              <h4 class="flex-1 min-w-0 text-sm font-bold text-slate-100 truncate group-hover:text-white transition-colors">
                {{ lead.title }}
              </h4>
              <span :class="[
                'shrink-0 text-[11px] px-2 py-0.5 rounded-lg font-bold',
                lead.grade === 'A'
                  ? 'bg-red-500/15 text-red-400 border border-red-500/25'
                  : lead.grade === 'B'
                    ? 'bg-amber-500/15 text-amber-300 border border-amber-500/25'
                    : 'bg-slate-700/30 text-slate-300 border border-slate-600/50'
              ]">
                {{ lead.grade }}级 {{ lead.totalScore }}分
              </span>
            </div>

            <!-- 第二行：发布单位 + 行政区域 -->
            <div class="flex items-center justify-between gap-2 min-w-0">
              <div class="flex items-center gap-1.5 text-xs text-slate-400 min-w-0">
                <Building2 class="h-3.5 w-3.5 text-slate-500 shrink-0" />
                <span class="truncate">{{ lead.company }}</span>
              </div>
              <span v-if="getLeadProvince(lead) || getDisplayRegion(lead)" class="shrink-0 max-w-[140px] truncate text-[9px] font-bold text-cyan-300 bg-cyan-500/10 border border-cyan-500/25 px-1.5 py-0.5 rounded">
                行政区域 {{ getLeadProvince(lead) || getDisplayRegion(lead) }}
              </span>
            </div>

            <!-- 第三行：发布时间 + 抓取时间（无值不展示） -->
            <div v-if="lead.publishDate || lead.crawlTime" class="mt-1.5 flex items-center gap-3 text-[10px] text-slate-500 font-mono min-w-0">
              <span v-if="lead.publishDate" class="truncate">发布时间：{{ lead.publishDate }}</span>
              <span v-if="lead.crawlTime" class="truncate shrink-0">抓取时间：{{ (lead.crawlTime || '').replace('T', ' ').replace(/\+.*$/, '').slice(0, 16) }}</span>
            </div>

            <!-- 底部状态条：高价值/加急 + 状态 + 跟进人 -->
            <div class="mt-2.5 flex items-center justify-between gap-2 border-t border-slate-700/50 pt-2 min-w-0">
              <div class="flex items-center gap-1.5 min-w-0">
                <span v-if="lead.totalScore >= scoringRule.warningThreshold" class="shrink-0 flex items-center gap-0.5 text-[9px] bg-red-600 text-white px-1.5 py-0.5 rounded font-bold shadow-sm">
                  <AlertTriangle class="h-2.5 w-2.5" />
                  <span>高价值</span>
                </span>
                <span v-if="lead.isUrgent" class="shrink-0 text-[9px] bg-rose-600 text-white px-1.5 py-0.5 rounded font-bold shadow-sm">加急</span>
                <span :class="[
                  'shrink-0 text-[10px] px-1.5 py-0.5 rounded-lg font-medium',
                  statusConfig[lead.status]?.bg || 'bg-slate-800',
                  statusConfig[lead.status]?.color || 'text-slate-400',
                ]">
                  {{ lead.status }}
                </span>
                <span v-if="lead.followUpPerson" class="text-[10px] text-slate-300 bg-slate-900/60 border border-slate-700/50 rounded-lg px-2 py-0.5 flex items-center gap-1 min-w-0 shadow-inner">
                  <span>👤</span>
                  <span class="font-medium truncate">{{ lead.followUpPerson }}</span>
                </span>
              </div>
              <span v-if="lead.crawlTime" class="shrink-0 text-[10px] text-slate-500 font-mono" :title="(lead.crawlTime || '').replace('T', ' ').replace(/\+.*$/, '')">
                {{ relativeTime(lead.crawlTime) }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 右侧主控卡片：线索详情研判板 -->
    <div class="flex-1 rounded-2xl border border-slate-800/80 shadow-2xl flex flex-col bg-slate-900 relative overflow-hidden">

      <div v-if="selectedLead" class="flex-1 flex flex-col overflow-y-auto scrollbar-thin relative">

        <!-- ===== 固定标头区：融合沉浸式毛玻璃 ===== -->
        <div class="sticky top-0 z-20 bg-slate-900/80 backdrop-blur-xl border-b border-slate-800/80 pt-5 px-6 pb-5 shadow-sm">
          <!-- 内嵌焦点卡片 -->
          <div class="bg-slate-800/40 p-5 rounded-2xl border border-slate-700/50 shadow-md relative overflow-hidden">
            <div class="flex items-start justify-between relative z-10 gap-6">
              <div class="space-y-2 min-w-0 flex-1">
                <div class="flex items-center gap-2 flex-wrap">
                  <span class="text-[11px] font-mono text-slate-400 bg-slate-900/60 px-2 py-0.5 rounded-md border border-slate-700/50 shadow-inner">
                    建设地点：{{ getDisplayRegion(selectedLead) }}
                  </span>
                </div>

                <h2 class="text-xl font-extrabold text-slate-100 tracking-tight leading-snug flex items-center gap-2">
                  <button
                      @click="emit('toggle-favorite', selectedLead.id)"
                      class="shrink-0 text-lg leading-none transition drop-shadow-sm"
                      :class="selectedLead.isFavorite ? 'text-amber-400 hover:text-amber-300' : 'text-slate-500 hover:text-amber-300'"
                      :title="selectedLead.isFavorite ? '取消收藏' : '收藏'"
                  >
                    {{ selectedLead.isFavorite ? '★' : '☆' }}
                  </button>
                  <span class="min-w-0 flex-1">{{ selectedLead.title }}</span>
                  <a v-if="selectedLead.sourceDb && selectedLead.sourceDb.startsWith('http')"
                     :href="selectedLead.sourceDb"
                     target="_blank"
                     rel="noopener noreferrer"
                     class="shrink-0 inline-flex items-center gap-1 text-xs font-medium text-white bg-blue-600 hover:bg-blue-500 border border-blue-700 hover:border-blue-600 px-2 py-1 rounded-lg transition-colors shadow-sm shadow-blue-900/30"
                     @click.stop>
                    <ExternalLink class="h-3.5 w-3.5" />
                    原文
                  </a>
                </h2>

                <p class="text-sm font-semibold text-slate-300 flex items-center gap-1.5">
                  <Building2 class="h-4 w-4 text-slate-400 shrink-0" />
                  <span>{{ selectedLead.company }}</span>
                </p>

                <!-- 退回原因横幅 -->
                <div v-if="selectedLead.returnReason" class="mt-3 bg-amber-500/10 border border-amber-500/20 text-amber-400 p-3 rounded-xl text-xs flex items-start gap-2 shadow-sm">
                  <AlertCircle class="h-4 w-4 shrink-0 mt-0.5" />
                  <div>
                    <span class="font-bold">线索退回原因：</span>
                    <span>{{ selectedLead.returnReason }}</span>
                  </div>
                </div>
              </div>

              <!-- 状态与评分变更器 -->
              <div class="text-right space-y-2.5 shrink-0 bg-slate-900/40 p-3.5 rounded-xl border border-slate-700/50 shadow-inner">
                <div class="text-slate-400 text-[10px] font-mono mb-1 uppercase tracking-wider">跟进生命周期</div>
                <select
                    v-if="selectedLead.status !== '已转化'"
                    :value="selectedLead.status"
                    @change="handleStatusSelectChange"
                    class="bg-slate-900/80 font-bold text-xs border border-slate-600/50 rounded-lg px-3 py-2 text-cyan-400 outline-none focus:ring-1 focus:ring-cyan-500/30 min-w-[120px] shadow-sm cursor-pointer"
                >
                  <option v-for="opt in availableStatusOptions" :key="opt" :value="opt">【{{ opt }}】</option>
                </select>
                <span v-else class="inline-block bg-emerald-500/15 border border-emerald-500/30 text-emerald-400 text-xs font-bold px-3 py-2 rounded-lg cursor-default shadow-sm shadow-emerald-900/20">
                  【已转化】
                </span>

                <div class="text-xs text-slate-300 block pt-1">
                  综合评分: <span class="font-extrabold text-lg text-cyan-400 drop-shadow-sm">{{ selectedLead.totalScore }}</span> 分
                </div>
                <button
                    v-if="selectedLead.status === '跟进中' && (currentRole === '超级管理员' || currentRole === '商务负责人' || currentRole === '商务专员')"
                    @click="emit('convert-lead', selectedLead.id)"
                    class="w-full bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white text-xs font-bold px-3 py-2 rounded-lg flex items-center justify-center gap-1.5 transition shadow-md shadow-blue-900/30"
                >
                  <Building2 class="h-3.5 w-3.5" />
                  <span>转为客户</span>
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- ===== 内容主体区 ===== -->
        <div class="p-6 space-y-6 flex-1">

          <!-- 5 维综合评估 (内嵌小卡片) -->
          <div class="bg-slate-800/40 p-5 rounded-2xl border border-slate-700/50 shadow-md">
            <h3 class="text-xs font-bold text-slate-200 uppercase tracking-wider mb-5 flex items-center gap-2">
              <Sliders class="h-4 w-4 text-slate-400" />
              5 维综合评估
            </h3>
            <div class="space-y-4">
              <div v-for="dim in scoreBreakdownWithFlag" :key="dim.label" class="flex items-center gap-3">
                <span class="w-16 shrink-0 text-xs text-slate-300 font-medium">{{ dim.label }}</span>
                <div class="flex-1 h-2.5 bg-slate-900/80 shadow-inner rounded-full overflow-hidden">
                  <div
                      class="h-full rounded-full transition-all"
                      :class="dim.isMax ? 'bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]' : dim.isMin ? 'bg-orange-500 shadow-[0_0_8px_rgba(249,115,22,0.5)]' : 'bg-cyan-500 shadow-[0_0_8px_rgba(6,182,212,0.5)]'"
                      :style="{ width: Math.min(100, Math.max(0, dim.score)) + '%' }"
                  ></div>
                </div>
                <div class="shrink-0 w-40 flex items-baseline justify-end gap-2.5">
                  <span class="text-sm font-extrabold drop-shadow-sm" :class="dim.isMax ? 'text-emerald-400' : dim.isMin ? 'text-orange-400' : 'text-slate-100'">
                    {{ dim.score }}
                  </span>
                  <span class="text-[11px] text-slate-500 bg-slate-900/50 px-1.5 py-0.5 rounded">权 {{ dim.weight }}%</span>
                  <span class="text-[11px] text-cyan-300 font-bold">加权 {{ dim.weighted }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- 快捷分配与操作中心 -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">

            <!-- 联系人卡片（动态边框与光晕） -->
            <div class="bg-slate-800/40 p-5 rounded-2xl border flex flex-col space-y-4" :class="contactCardBorderClass">
              <span class="text-xs font-bold text-slate-200 uppercase tracking-wider flex items-center gap-2">
                <Building2 class="h-4 w-4" />
                公募商机对接渠道
              </span>
              <div class="grid grid-cols-2 gap-3">
                <div class="bg-slate-900/60 p-3 rounded-xl border border-slate-700/40 shadow-inner">
                  <span class="text-xs text-slate-400 block mb-1">招投标联系人</span>
                  <input
                      v-if="canEditContact"
                      v-model="editContactName"
                      type="text"
                      maxlength="50"
                      placeholder="待补充，可手动填写"
                      class="w-full bg-slate-800/50 border border-slate-600/50 rounded-lg text-sm font-bold text-slate-100 px-2.5 py-1.5 outline-none focus:border-cyan-500/60 focus:ring-1 focus:ring-cyan-500/30 placeholder:text-slate-500 placeholder:font-normal transition shadow-sm"
                  />
                  <span v-else class="text-sm font-bold text-slate-200 block py-1.5 px-1 cursor-default">
                    {{ selectedLead.contactName || '待补充' }}
                  </span>
                </div>
                <div class="bg-slate-900/60 p-3 rounded-xl border border-slate-700/40 shadow-inner">
                  <span class="text-xs text-slate-400 block mb-1 flex items-center gap-1">
                    <span>联系电话</span>
                  </span>
                  <input
                      v-if="canEditContact"
                      v-model="editContactPhone"
                      type="text"
                      maxlength="30"
                      placeholder="待补充，可手动填写"
                      class="w-full bg-slate-800/50 border border-slate-600/50 rounded-lg text-sm font-bold text-cyan-400 font-mono px-2.5 py-1.5 outline-none focus:border-cyan-500/60 focus:ring-1 focus:ring-cyan-500/30 placeholder:text-slate-500 placeholder:font-normal transition shadow-sm"
                  />
                  <p v-if="editPhoneError" class="text-[11px] text-rose-400 mt-1.5">{{ editPhoneError }}</p>
                  <span v-if="!canEditContact" class="text-sm font-bold text-cyan-400 font-mono block py-1.5 px-1 cursor-default">
                    {{ maskPhone(selectedLead.contactPhone) }}
                  </span>
                </div>
              </div>
              <div v-if="canEditContact" class="flex items-center justify-between gap-2">
                <span class="text-[11px] text-slate-500">抓取未识别时可手动补全</span>
                <button
                    type="button"
                    @click="saveContact"
                    :disabled="!contactDirty"
                    class="text-xs font-semibold px-4 py-2 rounded-lg border transition disabled:opacity-40 disabled:cursor-not-allowed bg-cyan-500/15 border-cyan-500/30 text-cyan-300 hover:bg-cyan-500/25 shadow-sm"
                >
                  保存联系人
                </button>
              </div>

              <div class="pt-3 mt-auto border-t border-slate-700/50 flex flex-wrap items-center justify-between gap-3">
                <div v-if="selectedLead.budgetAmount" class="flex items-center gap-2 bg-slate-900/60 px-3 py-1.5 rounded-lg border border-slate-700/50 shadow-inner">
                  <span class="text-[11px] text-slate-400">预算:</span>
                  <span class="text-sm font-bold text-emerald-400">{{ selectedLead.budgetAmount }} 万</span>
                </div>
                <div class="flex items-center gap-2 flex-1 min-w-[180px]">
                  <span class="text-[11px] text-slate-400 font-medium shrink-0">跟进人:</span>
                  <select
                      v-if="canManage"
                      :value="selectedLead.followUpPerson || ''"
                      @change="emit('assign-person', { leadId: selectedLead.id, person: ($event.target as HTMLSelectElement).value })"
                      class="bg-slate-900/80 text-xs text-slate-200 border border-slate-600/50 shadow-sm rounded-lg px-2.5 py-1.5 outline-none focus:ring-1 focus:ring-cyan-500/30 min-w-0 flex-1 cursor-pointer"
                  >
                    <option value="">指派跟进人</option>
                    <option v-for="user in assignableUsers" :key="user.name" :value="user.name">{{ user.name }}</option>
                  </select>
                  <span v-else class="text-xs text-slate-200 font-medium truncate bg-slate-900/60 px-2 py-1.5 rounded-lg border border-slate-700/50 shadow-inner flex-1 cursor-default">
                    {{ selectedLead.followUpPerson || '未指派' }}
                  </span>
                </div>
              </div>
            </div>

            <!-- AI 快捷触发面板 -->
            <div class="bg-slate-800/40 rounded-2xl border border-slate-700/50 shadow-md self-start w-full overflow-hidden">
              <button
                  @click="showAiPanel = !showAiPanel"
                  class="w-full p-5 flex items-center justify-between gap-2 transition hover:bg-slate-700/30"
              >
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wider flex items-center gap-2">
                  <Sparkles class="h-4 w-4 text-cyan-400" />
                  AI 智能辅助转化决策
                </span>
                <ChevronDown :class="['h-4 w-4 text-slate-400 transition-transform duration-200', showAiPanel ? 'rotate-180' : '']" />
              </button>
              <div v-if="showAiPanel" class="px-5 pb-5 space-y-3">
                <div class="grid grid-cols-1 gap-2.5">
                  <button @click="emit('switch-tab', 'research')" class="flex items-center justify-center gap-2 bg-slate-900/60 hover:bg-slate-800 border border-cyan-500/30 hover:border-cyan-500/60 text-cyan-400 text-xs font-semibold py-2.5 rounded-xl transition shadow-sm">
                    <Database class="h-4 w-4 shrink-0" />
                    <span>AI 穿透快研</span>
                  </button>
                  <button @click="emit('switch-tab', 'competitors')" class="flex items-center justify-center gap-2 bg-slate-900/60 hover:bg-slate-800 border border-purple-500/30 hover:border-purple-500/60 text-purple-400 text-xs font-semibold py-2.5 rounded-xl transition shadow-sm">
                    <Layers class="h-4 w-4 shrink-0" />
                    <span>AI 破局分析</span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- 需求与备注记录（两列等高） -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 items-stretch">

            <!-- 原文需求诉求 -->
            <div class="bg-slate-800/40 p-5 rounded-2xl border border-slate-700/50 shadow-md flex flex-col h-full">
              <span class="text-xs font-bold text-slate-200 uppercase tracking-wider block mb-3">业主公告与工程详细诉求</span>
              <div class="flex-1 text-xs text-slate-300 leading-relaxed bg-slate-900/60 p-4 rounded-xl border border-slate-700/40 shadow-inner whitespace-pre-wrap">
                {{ cleanRequirements }}
              </div>
              <div class="mt-3 text-[11px] text-slate-500 font-mono text-right bg-slate-900/40 py-1.5 px-2 rounded-lg border border-slate-800/50">
                发布于 {{ selectedLead.publishDate }} · {{ getDisplayRegion(selectedLead) }}
              </div>
            </div>

            <!-- 跟进内容面板（与左侧需求卡片等高，记录超出时内部滚动） -->
            <div class="bg-slate-800/40 rounded-2xl border border-slate-700/50 shadow-md flex flex-col overflow-hidden h-full min-h-0" style="min-height:0">
              <button
                  @click="showFollowPanel = !showFollowPanel"
                  class="w-full p-5 flex items-center justify-between gap-2 transition hover:bg-slate-700/30"
              >
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wider flex items-center gap-2">
                  <Activity class="h-4 w-4 text-emerald-400" />
                  跟进记录 ({{ commentActivities.length }})
                </span>
                <span class="flex items-center gap-2 shrink-0">
                  <button
                      @click.stop="showOperationModal = true"
                      class="text-[10px] text-cyan-400 hover:text-cyan-300 bg-cyan-950/30 px-2 py-1 rounded border border-cyan-900/50 flex items-center gap-1 transition font-medium"
                  >
                    <Activity class="h-3 w-3" />时间线
                  </button>
                  <ChevronDown :class="['h-4 w-4 text-slate-400 transition-transform duration-200', showFollowPanel ? 'rotate-180' : '']" />
                </span>
              </button>

              <div v-if="showFollowPanel" class="px-5 pb-5 flex flex-col flex-1 min-h-0 relative" style="min-height:0">
                <!-- 输入框槽位（内容上方） -->
                <div v-if="(selectedLead?.followUpPerson === operatorName || canManage)" class="mb-4">
                  <div class="flex items-center gap-2 bg-slate-900/60 shadow-inner border border-slate-700/50 rounded-xl pl-3 pr-1.5 py-1.5 focus-within:border-cyan-500/50 focus-within:ring-1 focus-within:ring-cyan-500/20 transition">
                    <input
                        v-model="newActivityContent"
                        type="text"
                        placeholder="输入跟进内容，回车提交..."
                        class="flex-1 min-w-0 bg-transparent text-xs text-slate-200 py-1 focus:outline-none placeholder-slate-500"
                        @keyup.enter="submitActivity"
                    />
                    <button
                        type="button"
                        :disabled="uploadingImages"
                        @click="imageInput?.click()"
                        class="shrink-0 h-8 w-8 flex items-center justify-center rounded-lg hover:bg-slate-800 hover:text-cyan-400 text-slate-400 transition shadow-sm border border-transparent hover:border-slate-700/50"
                        :title="uploadingImages ? '上传中...' : '添加图片'"
                    >
                      <ImageIcon class="h-4 w-4" />
                    </button>
                    <input ref="imageInput" type="file" accept="image/*" multiple class="hidden" @change="handleUploadImage" />
                    <button
                        @click="submitActivity"
                        :disabled="(!newActivityContent.trim() && pendingImages.length === 0) || uploadingImages"
                        class="shrink-0 text-xs font-bold px-4 py-2 rounded-lg border transition-colors duration-200"
                        :class="((!newActivityContent.trim() && pendingImages.length === 0) || uploadingImages)
    ? 'bg-slate-800/40 border-slate-700/40 text-slate-600 cursor-not-allowed'
    : 'bg-cyan-500/20 border-cyan-400/50 text-cyan-300 hover:bg-cyan-500/30'"
                    >
                      {{ uploadingImages ? '上传...' : '提交' }}
                    </button>
                  </div>
                  <div v-if="pendingImages.length > 0" class="flex gap-2 mt-2.5 flex-wrap bg-slate-900/40 p-2 rounded-lg border border-slate-800/50">
                    <template v-for="(img, idx) in pendingImages" :key="idx">
                      <div class="relative group">
                        <img :src="img.url" class="h-12 w-12 object-cover rounded-lg border border-slate-600/50 shadow-sm" alt="预览" />
                        <button type="button" @click="removePendingImage(idx)" class="absolute -top-1.5 -right-1.5 h-4 w-4 rounded-full bg-rose-500 text-white text-[10px] leading-none flex items-center justify-center hover:bg-rose-400 shadow-md">✕</button>
                      </div>
                    </template>
                  </div>
                </div>

                <!-- 记录列表（绝对定位：从输入框下方延伸到卡片底部，不撑高卡片） -->
                <div v-if="commentActivities.length > 0" class="space-y-2.5 absolute left-0 right-0 bottom-0 overflow-y-auto pr-1" style="overflow-y:auto">
                  <div v-for="act in commentActivities" :key="act.id" class="flex gap-3 p-3 rounded-xl bg-slate-900/40 border border-slate-700/50 shadow-sm">
                    <div class="shrink-0 mt-0.5">
                      <div class="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold bg-cyan-500/15 text-cyan-400 border border-cyan-500/30 shadow-inner">
                        {{ act.operator.charAt(0) }}
                      </div>
                    </div>
                    <div class="min-w-0 flex-1">
                      <div class="flex items-center justify-between gap-2">
                        <span class="text-xs font-bold text-slate-200">{{ act.operator }}</span>
                        <span class="text-[10px] text-slate-500 font-mono shrink-0">{{ act.createdAt }}</span>
                      </div>
                      <p v-if="stripImageMarkdown(act.content)" class="text-xs text-slate-300 mt-1 whitespace-pre-wrap break-words leading-relaxed">{{ stripImageMarkdown(act.content) }}</p>
                      <div v-if="extractImages(act.content).length > 0" class="flex gap-2 mt-2.5 flex-wrap">
                        <img v-for="(url, i) in extractImages(act.content)" :key="i" :src="url" class="h-16 w-16 object-cover rounded-lg border border-slate-600/50 shadow-sm cursor-pointer hover:border-cyan-500/50 transition hover:scale-105" @click="viewerUrl = url" />
                      </div>
                    </div>
                  </div>
                </div>
                <div v-else class="flex-1 flex flex-col items-center justify-center text-slate-500 text-xs py-8 bg-slate-900/30 rounded-xl border border-slate-800/50 border-dashed">
                  <Activity class="h-6 w-6 mb-2 text-slate-700" />
                  暂无跟进记录
                </div>
              </div>
            </div>
          </div>

          <!-- AI 智能资产光晕展示区 -->
          <div v-if="selectedLead.preResearchReport || selectedLead.competitorAnalysis" class="pt-2 space-y-4">
            <h3 class="text-[11px] font-bold text-slate-400 uppercase tracking-widest flex items-center gap-2">
              <Sparkles class="h-3.5 w-3.5 text-cyan-500 shrink-0" />
              <span>已就绪的本地大模型智能研判资产</span>
              <div class="h-[1px] flex-1 bg-gradient-to-r from-slate-700/50 to-transparent"></div>
            </h3>

            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <div v-if="selectedLead.preResearchReport" class="bg-emerald-950/20 p-5 rounded-2xl border border-emerald-500/20 hover:border-emerald-500/40 shadow-lg hover:shadow-emerald-900/20 transition flex flex-col justify-between group relative overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-emerald-500/5 to-transparent pointer-events-none"></div>
                <div class="relative z-10">
                  <div class="flex items-center justify-between mb-3">
                    <span class="text-xs font-bold text-emerald-400 flex items-center gap-1.5 drop-shadow-sm">
                      <CheckCircle class="h-4 w-4" />
                      <span>穿透快研完成</span>
                    </span>
                    <span class="text-[10px] text-emerald-500/70 font-mono bg-emerald-950/40 px-2 py-0.5 rounded border border-emerald-900/50">{{ selectedLead.researchDate }}</span>
                  </div>
                  <p class="text-xs text-slate-300 line-clamp-3 leading-relaxed">
                    梳理了该集团的3大核心被动合规性痛点，已得出致胜切入点。
                  </p>
                </div>
                <button @click="emit('switch-tab', 'research')" class="relative z-10 text-xs font-semibold text-cyan-400 hover:text-cyan-300 flex items-center mt-4 transition drop-shadow-sm w-fit bg-cyan-950/30 px-3 py-1.5 rounded-lg border border-cyan-900/50 hover:bg-cyan-900/40">
                  <span>立即开卷阅读</span>
                  <ChevronRight class="h-3.5 w-3.5 ml-1 group-hover:translate-x-0.5 transition-transform" />
                </button>
              </div>

              <div v-if="selectedLead.competitorAnalysis" class="bg-purple-950/20 p-5 rounded-2xl border border-purple-500/20 hover:border-purple-500/40 shadow-lg hover:shadow-purple-900/20 transition flex flex-col justify-between group relative overflow-hidden">
                <div class="absolute inset-0 bg-gradient-to-br from-purple-500/5 to-transparent pointer-events-none"></div>
                <div class="relative z-10">
                  <div class="flex items-center justify-between mb-3">
                    <span class="text-xs font-bold text-purple-400 flex items-center gap-1.5 drop-shadow-sm">
                      <CheckCircle class="h-4 w-4" />
                      <span>破局竞合分析报告已发</span>
                    </span>
                    <span class="text-[10px] text-purple-500/70 font-mono bg-purple-950/40 px-2 py-0.5 rounded border border-purple-900/50">{{ selectedLead.competitorDate }}</span>
                  </div>
                  <p class="text-xs text-slate-300 line-clamp-3 leading-relaxed">
                    分析了中科绿控、科创低碳等本市区大户，并规划差异化打击切入。
                  </p>
                </div>
                <button @click="emit('switch-tab', 'competitors')" class="relative z-10 text-xs font-semibold text-cyan-400 hover:text-cyan-300 flex items-center mt-4 transition drop-shadow-sm w-fit bg-cyan-950/30 px-3 py-1.5 rounded-lg border border-cyan-900/50 hover:bg-cyan-900/40">
                  <span>进入破局战术室</span>
                  <ChevronRight class="h-3.5 w-3.5 ml-1 group-hover:translate-x-0.5 transition-transform" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- 底部悬浮操作区 -->
        <div class="sticky bottom-0 z-20 bg-slate-900/85 backdrop-blur-xl border-t border-slate-800/80 px-6 py-4 mt-auto">
          <div class="flex justify-between items-center text-xs text-slate-400">
            <span class="flex items-center gap-1.5 bg-slate-800/50 px-2.5 py-1 rounded-md border border-slate-700/50 shadow-inner">
              <span>操作人:</span>
              <span class="font-bold text-slate-200">{{ operatorName }}</span>
            </span>
            <button
                v-if="canManage"
                @click="emit('delete-lead', selectedLead.id)"
                class="text-rose-400 hover:text-rose-300 flex items-center gap-1.5 font-semibold transition bg-rose-950/30 hover:bg-rose-900/40 px-3 py-1.5 rounded-lg border border-rose-900/50 shadow-sm"
            >
              <Trash2 class="h-3.5 w-3.5" />
              <span>剔除商机</span>
            </button>
          </div>
        </div>
      </div>

      <!-- 未选中线索的空状态 -->
      <div v-else class="flex-1 flex flex-col items-center justify-center text-slate-400 p-12 text-center bg-slate-900/50 relative">
        <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-slate-800/20 via-transparent to-transparent pointer-events-none"></div>
        <div class="w-24 h-24 rounded-full bg-slate-800/50 border border-slate-700/50 flex items-center justify-center mb-5 shadow-lg relative z-10">
          <Database class="h-12 w-12 text-slate-600" />
        </div>
        <p class="text-lg font-bold text-slate-200 mb-2 relative z-10">选择一条线索开始研判</p>
        <p class="text-xs text-slate-500 max-w-[280px] leading-relaxed relative z-10">在左侧「监测线索库」中点击任意线索，右侧将展示完整详情与多层 AI 辅助决策面板。</p>
      </div>
    </div>

    <!-- 弹窗部分 (模态窗底层样式保留, 小幅美化卡片和按钮) -->
    <!-- 导入 Excel 弹窗 -->
    <div v-if="showImportModal" class="fixed inset-0 z-[60] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 text-left" @click.self="showImportModal = false">
      <div class="bg-white rounded-2xl max-w-md w-full p-6 space-y-5 shadow-2xl border border-gray-200" style="color:#000000!important">
        <div class="flex items-center gap-4">
          <div class="w-12 h-12 rounded-full bg-cyan-50 flex items-center justify-center shrink-0 border border-cyan-100">
            <Database class="h-6 w-6 text-cyan-600" />
          </div>
          <div>
            <h3 class="text-lg font-bold text-gray-900">Excel 批量导入线索</h3>
            <p class="text-xs mt-1 text-gray-500">支持 .xlsx / .xls 格式, 需含标题、企业名称及行政所属区。</p>
          </div>
        </div>
        <div class="space-y-4">
          <div class="bg-gray-50 p-4 rounded-xl border border-gray-200 shadow-inner">
            <label class="text-sm block mb-2 font-bold text-gray-700">选择 Excel 文件</label>
            <input type="file" accept=".xlsx,.xls" @change="importFile = ($event.target as HTMLInputElement).files?.[0] || null" class="text-xs file:mr-3 file:py-1.5 file:px-4 file:rounded-lg file:border-0 file:text-xs file:font-bold file:bg-cyan-600 file:text-white hover:file:bg-cyan-500 file:cursor-pointer file:shadow-md" style="color:#0f172a!important" />
          </div>
          <div class="flex items-center gap-3 bg-gray-50 p-3 rounded-xl border border-gray-200">
            <label class="text-xs font-bold text-gray-700">重复处理:</label>
            <select v-model="importDuplicateAction" class="bg-white border border-gray-300 text-xs px-3 py-1.5 rounded-lg shadow-sm font-medium" style="color:#0f172a!important">
              <option value="skip">跳过重复项</option>
              <option value="overwrite">覆盖原线索</option>
            </select>
          </div>
        </div>
        <div class="flex justify-between items-center pt-2">
          <button type="button" @click="emit('download-template')" class="text-xs font-bold text-cyan-600 hover:text-cyan-500 underline underline-offset-4">下载导入模板</button>
          <div class="flex gap-3">
            <button type="button" @click="showImportModal = false" class="bg-white hover:bg-gray-50 border border-gray-300 text-xs font-bold px-4 py-2 rounded-xl transition text-gray-700 shadow-sm">取消</button>
            <button type="button" :disabled="!importFile || importLoading" @click="importFile && (importLoading = true) && emit('import-leads', importFile, importDuplicateAction)" class="bg-cyan-600 hover:bg-cyan-500 border border-cyan-700 text-xs font-bold px-5 py-2 rounded-xl transition text-white shadow-md disabled:opacity-50">
              {{ importLoading ? '导入中...' : '确认导入' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- 超级管理员退回原因弹窗 -->
    <div v-if="showReturnModal" class="fixed inset-0 z-[60] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 text-left" @click.self="cancelReturn">
      <div class="bg-white rounded-2xl max-w-md w-full p-6 space-y-5 shadow-2xl border border-gray-200">
        <div class="flex items-center gap-4">
          <div class="w-12 h-12 rounded-full bg-amber-50 flex items-center justify-center shrink-0 border border-amber-100">
            <AlertCircle class="h-6 w-6 text-amber-600" />
          </div>
          <div>
            <h3 class="text-lg font-bold text-gray-900">退回线索跟进状态</h3>
            <p class="text-xs mt-1 text-gray-500">此操作需要超级管理员权限，全程审计留痕。</p>
          </div>
        </div>
        <p class="text-xs bg-amber-50 p-3 rounded-xl border border-amber-200 text-amber-900">
          您正将线索 <span class="font-bold">「{{ selectedLead?.title }}」</span> 从 <span class="font-bold text-amber-600">{{ selectedLead?.status }}</span> 退回至 <span class="font-bold text-purple-600">跟进中</span>
        </p>
        <div class="space-y-2">
          <label class="text-sm block font-bold text-gray-700">退回原因 <span class="text-rose-500">*</span></label>
          <textarea v-model="returnReasonInput" rows="3" placeholder="请填写退回原因，如：客户重新流露意向..." class="bg-gray-50 border border-gray-300 p-3 text-xs rounded-xl w-full focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/30 placeholder-gray-400 resize-none shadow-inner text-gray-900 font-medium"></textarea>
        </div>
        <div class="flex justify-end gap-3 pt-2">
          <button type="button" @click="cancelReturn" class="bg-white hover:bg-gray-50 border border-gray-300 text-xs font-bold px-4 py-2 rounded-xl transition text-gray-700 shadow-sm">取消</button>
          <button type="button" @click="confirmReturn" class="bg-amber-600 hover:bg-amber-500 border border-amber-700 text-xs font-bold px-5 py-2 rounded-xl transition text-white shadow-md shadow-amber-600/20">确认退回</button>
        </div>
      </div>
    </div>

    <!-- 完整操作记录弹窗 (暗色系匹配主面板) -->
    <div v-if="showOperationModal" class="fixed inset-0 z-[60] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 text-left" @click.self="showOperationModal = false">
      <div class="bg-slate-900 border border-slate-700/80 rounded-2xl shadow-2xl w-full max-w-[600px] max-h-[80vh] flex flex-col overflow-hidden relative">
        <div class="flex items-center justify-between p-5 border-b border-slate-800/80 bg-slate-800/50 shrink-0">
          <span class="text-sm font-bold text-slate-200 uppercase tracking-wider flex items-center gap-2">
            <Activity class="h-4 w-4 text-cyan-400" />
            完整操作生命周期
          </span>
          <button @click="showOperationModal = false" class="text-slate-400 hover:text-slate-200 transition bg-slate-800 hover:bg-slate-700 rounded-full w-7 h-7 flex items-center justify-center shadow-sm">
            ✕
          </button>
        </div>
        <div class="flex-1 overflow-y-auto p-5 scrollbar-thin">
          <div v-if="allActivities.length > 0" class="space-y-3 relative before:absolute before:inset-0 before:ml-[1.1rem] before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-slate-700/80 before:via-slate-700/40 before:to-transparent">
            <div v-for="act in allActivities" :key="act.id" class="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active">
              <div class="flex items-center justify-center w-9 h-9 rounded-full border border-slate-700 bg-slate-800 text-slate-400 shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 relative z-10">
                <Activity class="h-4 w-4" />
              </div>
              <div class="w-[calc(100%-3rem)] md:w-[calc(50%-2rem)] p-3.5 rounded-xl bg-slate-800/50 border border-slate-700/50 shadow-md">
                <div class="flex items-center justify-between gap-2 mb-1">
                  <span class="text-xs font-bold text-slate-300">{{ act.operator }}</span>
                  <span class="text-[10px] text-slate-500 font-mono bg-slate-900/60 px-1.5 py-0.5 rounded border border-slate-800/50">{{ act.createdAt }}</span>
                </div>
                <p class="text-xs text-slate-300 mt-1 whitespace-pre-wrap break-words leading-relaxed">{{ stripImageMarkdown(act.content) }}</p>
                <div v-if="extractImages(act.content).length > 0" class="flex gap-2 mt-2 flex-wrap">
                  <img v-for="(url, i) in extractImages(act.content)" :key="i" :src="url" class="h-16 w-16 object-cover rounded-lg border border-slate-600/50 cursor-pointer hover:border-cyan-500/50 transition hover:scale-105 shadow-sm" @click="viewerUrl = url" />
                </div>
              </div>
            </div>
          </div>
          <div v-else class="text-xs text-slate-500 py-12 text-center bg-slate-800/30 rounded-xl border border-slate-700/50 border-dashed">
            暂无操作记录
          </div>
        </div>
      </div>
    </div>

    <!-- 图片全屏查看 -->
    <div v-if="viewerUrl" class="fixed inset-0 z-[70] flex items-center justify-center bg-black/90 backdrop-blur-md p-6" @click.self="viewerUrl = null">
      <button @click="viewerUrl = null" class="absolute top-6 right-6 text-slate-300 hover:text-white text-xl w-10 h-10 flex items-center justify-center rounded-full bg-white/10 hover:bg-white/20 border border-white/20 transition shadow-lg backdrop-blur-md">
        ✕
      </button>
      <img :src="viewerUrl" class="max-w-full max-h-full rounded-2xl shadow-2xl border border-slate-800/80" alt="图片预览" />
    </div>

  </div>
</template>