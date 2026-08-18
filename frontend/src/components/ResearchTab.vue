<template>
  <div class="flex-1 p-6 flex overflow-hidden gap-4">
    <!-- 主区域 -->
    <div class="flex-1 flex flex-col bg-slate-950/40 border border-slate-800 rounded-2xl overflow-hidden min-w-0">
      <div class="p-4 bg-slate-950 border-b border-slate-800 flex flex-wrap justify-between items-center gap-3 shrink-0">
        <div class="flex items-center space-x-2">
          <Database class="h-5 w-5 text-cyan-400" />
          <div>
            <h4 class="text-sm font-bold text-slate-200">客户预调研 · 多源聚合与痛点研判</h4>
            <p class="text-xs text-slate-300">复用已抓取招投标线索自动聚合公开信息，生成痛点分析与对接建议，所有信息可溯源。</p>
          </div>
        </div>

        <div class="flex items-center gap-3 flex-wrap">
          <!-- 线索池全量商机快速查询/切换选择器 -->
          <div class="flex items-center gap-2">
            <button
              @click="showLeadPickerModal = true"
              class="flex items-center gap-1.5 bg-slate-900 hover:bg-slate-800 border border-slate-700 hover:border-cyan-500/50 text-slate-200 text-xs px-3 py-1.5 rounded-xl shadow-inner cursor-pointer transition active:scale-95"
              title="在全量商机线索池中进行智能搜索与选择"
            >
              <Search class="h-3.5 w-3.5 text-cyan-400 shrink-0" />
              <span class="truncate max-w-[180px]">{{ selectedLead ? `【${selectedLead.grade}级】${selectedLead.company || selectedLead.title}` : '检索商机线索池...' }}</span>
              <span class="text-[10px] text-cyan-400 bg-cyan-950/60 px-1.5 py-0.5 rounded font-mono border border-cyan-900/40">全量({{ leads?.length || 0 }})</span>
            </button>
          </div>

          <div class="flex items-center space-x-2">
            <span class="text-xs text-slate-300 shrink-0">分析倾向：</span>
            <input
              type="text"
              :value="researchGuide"
              @input="emit('update-guide', ($event.target as HTMLInputElement).value)"
              placeholder="例：倾向能耗/曝气降本切入"
              class="bg-slate-900 text-xs text-slate-300 border border-slate-800 rounded-xl px-3 py-1.5 w-48 focus:outline-none focus:ring-1 focus:ring-cyan-500"
            />
          </div>
        </div>
      </div>

      <div class="flex-1 overflow-y-auto p-6 space-y-5">
        <div v-if="selectedLead" class="space-y-5">
          <!-- 标的卡片 + 触发 -->
          <div class="bg-slate-900/50 p-4 rounded-xl border border-slate-800/60 shadow-sm">
            <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-3">
              <div>
                <div class="flex items-center gap-2 mb-1">
                  <span class="text-[10px] px-2 py-0.5 rounded font-bold" :class="getGradeBadgeClass(selectedLead.grade)">
                    {{ selectedLead.grade }}级商机 · {{ selectedLead.totalScore }}分
                  </span>
                  <span class="text-xs font-bold text-slate-400 uppercase">当前研判标的</span>
                </div>
                <h3 class="text-sm font-bold text-slate-200">{{ selectedLead.title }}</h3>
                <p class="text-xs text-slate-400 mt-0.5">{{ selectedLead.company }} · {{ selectedLead.region }} · 预算 {{ selectedLead.budgetAmount ? selectedLead.budgetAmount + '万' : '待补充' }}</p>
              </div>
              <button
                @click="emit('trigger-research', selectedLead.id)"
                :disabled="isResearching"
                class="bg-blue-600 hover:bg-blue-500 active:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white text-xs font-bold px-4 py-2 rounded-xl flex items-center space-x-2 shadow-md shadow-blue-900/30 transition shrink-0"
              >
                <Sparkles class="h-4 w-4 shrink-0" />
                <span>{{ isResearching ? '正在聚合与研判...' : '发起预调研 / 生成新版本' }}</span>
              </button>
            </div>
          </div>

          <div v-if="activeReport">
            <!-- 概览指标 -->
            <div class="flex items-center flex-wrap gap-2.5 mb-4">
              <span class="text-xs px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-800 text-slate-300">
                版本 <b>v{{ activeReport.version }}</b>
              </span>
              <span class="text-xs px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-800">
                信息完整度 <b :class="completenessColor">{{ activeReport.completeness }}%</b>
              </span>
              <span class="text-xs px-2.5 py-1 rounded-lg bg-cyan-950/40 border border-cyan-800/40 text-cyan-300 font-medium">
                研判引擎：<b>{{ getEngineText(activeReport.engine) }}</b>
              </span>
              <span class="text-xs px-2.5 py-1 rounded-lg bg-slate-900 border border-slate-800 text-slate-400">
                {{ formatTime(activeReport.createdAt) }}
              </span>

              <!-- 导出按钮组 (Word / PDF) -->
              <div class="flex items-center gap-1.5 ml-auto">
                <button
                  @click="exportWord"
                  class="cursor-pointer text-xs px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-500 text-white border border-blue-700 hover:border-blue-600 flex items-center space-x-1.5 transition active:scale-95 shadow-sm shadow-blue-900/30"
                  title="导出为 Word (.doc) 格式文档"
                >
                  <FileText class="h-3.5 w-3.5 text-white" />
                  <span>导出 Word</span>
                </button>
                <button
                  @click="exportPdf"
                  class="cursor-pointer text-xs px-3 py-1.5 rounded-lg bg-blue-600 hover:bg-blue-500 text-white border border-blue-700 hover:border-blue-600 flex items-center space-x-1.5 transition active:scale-95 shadow-sm shadow-blue-900/30"
                  title="导出为 PDF 格式或打印"
                >
                  <Download class="h-3.5 w-3.5 text-white" />
                  <span>导出 PDF</span>
                </button>
              </div>
            </div>

            <!-- 信息不足提示 -->
            <div v-if="!activeReport.isSufficient" class="flex items-start space-x-2 bg-amber-500/10 border border-amber-500/30 text-amber-400 text-xs rounded-xl p-3 mb-4">
              <AlertTriangle class="h-4 w-4 shrink-0 mt-0.5" />
              <span>公开信息不足，建议补充调研。下方仅为基础信息汇总，请勿据此直接决策。</span>
            </div>

            <!-- 结构化调研原始信息集 -->
            <div class="bg-slate-950 p-4 rounded-xl border border-slate-800 mb-4">
              <h5 class="text-xs font-bold text-cyan-400 mb-3 flex items-center"><Compass class="h-4 w-4 mr-1" />结构化调研原始信息集（可溯源）</h5>
              <div v-if="infoItems.length" class="space-y-2">
                <div v-for="item in infoItems" :key="item.label" class="text-xs text-slate-300 flex items-start">
                  <span class="text-slate-500 w-28 shrink-0">{{ item.label }}</span>
                  <span class="flex-1">
                    {{ item.value }}
                    <a v-if="item.source" :href="item.source" target="_blank" class="text-cyan-500 hover:text-cyan-400 inline-flex items-center ml-1 cursor-pointer">
                      <LinkIcon class="h-3 w-3" />
                    </a>
                  </span>
                </div>
              </div>
              <p v-else class="text-xs text-slate-500">未聚合到结构化字段，请查看下方缺失清单。</p>
            </div>

            <!-- 痛点分析报告全文 -->
            <div class="bg-slate-950 p-5 rounded-xl border border-slate-800 prose prose-invert max-w-none text-xs leading-relaxed text-slate-300 whitespace-pre-wrap font-sans mb-4">{{ activeReport.reportContent }}</div>

            <!-- 来源链接 -->
            <div v-if="activeReport.sources?.length" class="bg-slate-950 p-4 rounded-xl border border-slate-800 mb-4">
              <h5 class="text-xs font-bold text-slate-300 mb-2 flex items-center"><LinkIcon class="h-4 w-4 mr-1" />来源链接（{{ activeReport.sources.length }}）</h5>
              <ul class="space-y-1">
                <li v-for="(s, i) in activeReport.sources" :key="i" class="text-xs">
                  <a :href="s.url" target="_blank" class="text-cyan-500 hover:text-cyan-400 break-all">
                    <span v-if="s.label">{{ s.label }}</span>
                    <span v-else>{{ s.url }}</span>
                  </a>
                </li>
              </ul>
            </div>

            <!-- 历史相关公告 -->
            <div v-if="historyItems.length" class="bg-slate-950 p-4 rounded-xl border border-slate-800 mb-4">
              <h5 class="text-xs font-bold text-slate-300 mb-2 flex items-center"><FileText class="h-4 w-4 mr-1" />同单位历史招投标公告（{{ historyItems.length }}）</h5>
              <ul class="space-y-1.5">
                <li v-for="(h, i) in historyItems" :key="i" class="text-xs text-slate-400 flex items-start">
                  <span class="text-slate-600 w-24 shrink-0">{{ h.publishDate || '—' }}</span>
                  <span class="flex-1">
                    <a v-if="h.link" :href="h.link" target="_blank" class="text-slate-300 hover:text-cyan-400">{{ h.title }}</a>
                    <span v-else class="text-slate-300">{{ h.title }}</span>
                    <span v-if="h.sourceDb" class="text-[10px] text-slate-500 ml-2">【{{ h.sourceDb }}】</span>
                  </span>
                </li>
              </ul>
            </div>

            <!-- 缺失 / 待确认清单 -->
            <div v-if="activeReport.missingItems?.length" class="bg-slate-950 p-4 rounded-xl border border-amber-500/20">
              <h5 class="text-xs font-bold text-amber-400 mb-2 flex items-center"><AlertTriangle class="h-4 w-4 mr-1" />需进一步确认的信息清单</h5>
              <ul class="grid grid-cols-2 gap-1">
                <li v-for="(m, i) in activeReport.missingItems" :key="i" class="text-xs text-slate-400">· {{ m }}</li>
              </ul>
            </div>
          </div>

          <div v-else class="p-12 text-center text-slate-500 border-2 border-dashed border-slate-800 rounded-xl bg-slate-950/20">
            <Compass class="h-10 w-10 text-slate-700 mx-auto mb-2" />
            <span>该商机暂无预调研档案，请点击上方按钮发起聚合研判</span>
          </div>
        </div>

        <div v-else class="text-center p-12 text-slate-500">
          请点击右上角「检索商机线索池」选择线索，以开启对该企业的精准研判分析。
        </div>
      </div>
    </div>

    <!-- 版本历史侧栏 -->
    <div v-if="selectedLead" class="w-64 shrink-0 bg-slate-950/40 border border-slate-800 rounded-2xl flex flex-col overflow-hidden">
      <div class="p-4 bg-slate-950 border-b border-slate-800 flex justify-between items-center shrink-0">
        <div class="flex items-center space-x-1.5">
          <History class="h-4 w-4 text-cyan-400" />
          <h4 class="text-xs font-bold text-slate-200">研判版本归档</h4>
        </div>
        <span class="text-[10px] text-slate-500">{{ reports.length }} 个版本</span>
      </div>
      <div class="flex-1 overflow-y-auto p-3 space-y-2">
        <button
          v-for="r in reports"
          :key="r.id"
          @click="emit('select-version', r.id)"
          :class="[
            'w-full text-left p-3 rounded-xl border transition cursor-pointer',
            activeReport && activeReport.id === r.id
              ? 'bg-slate-700 border-slate-600'
              : 'bg-slate-900/40 border-slate-800 hover:border-slate-700'
          ]"
        >
          <div class="flex justify-between items-center mb-1">
            <span :class="['text-xs font-bold', activeReport && activeReport.id === r.id ? 'text-amber-500' : 'text-slate-200']">v{{ r.version }}</span>
            <span :class="['text-[10px] font-mono', activeReport && activeReport.id === r.id ? 'text-amber-400' : 'text-slate-500']">{{ formatTime(r.createdAt) }}</span>
          </div>
          <div :class="['text-[10px] flex justify-between', activeReport && activeReport.id === r.id ? 'text-amber-400' : 'text-slate-400']">
            <span>完整度 {{ r.completeness }}%</span>
            <span :class="activeReport && activeReport.id === r.id ? 'text-amber-500' : 'text-cyan-400'">{{ getEngineText(r.engine) }}</span>
          </div>
        </button>
        <p v-if="!reports.length" class="text-xs text-slate-500 text-center p-4">暂无历史版本</p>
      </div>
    </div>

    <!-- 全量线索池选择模态窗 -->
    <div v-if="showLeadPickerModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-fade-in" @click.self="showLeadPickerModal = false">
      <div class="bg-slate-900 border border-slate-700 rounded-2xl max-w-2xl w-full max-h-[85vh] flex flex-col overflow-hidden shadow-2xl">
        <div class="p-4 border-b border-slate-800 flex items-center justify-between shrink-0 bg-slate-950">
          <div class="flex items-center gap-2">
            <Search class="h-4 w-4 text-cyan-400" />
            <h4 class="text-sm font-bold text-slate-100">全网商机线索池 (共 {{ leads?.length || 0 }} 条)</h4>
          </div>
          <button @click="showLeadPickerModal = false" class="text-slate-400 hover:text-slate-200 cursor-pointer">
            <X class="h-4 w-4" />
          </button>
        </div>

        <div class="p-4 border-b border-slate-800 bg-slate-950/60">
          <div class="relative">
            <Search class="absolute left-3.5 top-2.5 h-4 w-4 text-slate-500" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="搜索企业名称、项目标题、地域、负责人、状态等..."
              class="w-full bg-slate-900 border border-slate-700 rounded-xl pl-10 pr-4 py-2 text-xs text-slate-200 focus:outline-none focus:border-cyan-500"
            />
          </div>
        </div>

        <div class="flex-1 overflow-y-auto p-4 space-y-2">
          <div
            v-for="lead in filteredPoolLeads"
            :key="lead.id"
            @click="handleSelectLeadChange(lead.id); showLeadPickerModal = false;"
            :class="[
              'p-3 rounded-xl border cursor-pointer transition flex items-center justify-between gap-3',
              selectedLead?.id === lead.id ? 'bg-cyan-950/30 border-cyan-500/50' : 'bg-slate-950 border-slate-800 hover:border-slate-700 hover:bg-slate-900'
            ]"
          >
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2 mb-1">
                <span class="text-[10px] px-1.5 py-0.5 rounded font-bold" :class="getGradeBadgeClass(lead.grade)">
                  {{ lead.grade }}级 · {{ lead.totalScore }}分
                </span>
                <span class="text-xs font-bold text-slate-200 truncate">{{ lead.title }}</span>
              </div>
              <div class="flex items-center gap-3 text-[11px] text-slate-400">
                <span class="truncate">{{ lead.company }}</span>
                <span>{{ lead.region }}</span>
                <span>{{ lead.status }}</span>
              </div>
            </div>
            <button class="shrink-0 text-xs text-cyan-400 bg-cyan-950/40 border border-cyan-900/60 px-3 py-1.5 rounded-lg font-medium cursor-pointer">
              {{ selectedLead?.id === lead.id ? '已选中' : '选择' }}
            </button>
          </div>

          <div v-if="filteredPoolLeads.length === 0" class="py-12 text-center text-slate-500 text-xs">
            未搜索到匹配的商机线索
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import html2canvas from 'html2canvas';
import { jsPDF } from 'jspdf';
import {
  Database,
  Sparkles,
  Compass,
  Link as LinkIcon,
  AlertTriangle,
  History,
  Download,
  FileText,
  Search,
  X
} from 'lucide-vue-next';
import { Lead, ResearchReport } from '../types';

const props = defineProps<{
  selectedLead: Lead | null;
  leads?: Lead[];
  isResearching: boolean;
  researchGuide: string;
  reports: ResearchReport[];
  activeReport: ResearchReport | null;
  currentRole?: string;
}>();

const emit = defineEmits<{
  (e: 'update-guide', val: string): void;
  (e: 'trigger-research', leadId: string): void;
  (e: 'select-version', reportId: string): void;
  (e: 'select-lead', lead: Lead): void;
}>();

const showLeadPickerModal = ref(false);
const searchQuery = ref('');

const filteredPoolLeads = computed(() => {
  const list = props.leads || [];
  if (!searchQuery.value.trim()) return list;
  const q = searchQuery.value.trim().toLowerCase();
  return list.filter((l) =>
    (l.title && l.title.toLowerCase().includes(q)) ||
    (l.company && l.company.toLowerCase().includes(q)) ||
    (l.region && l.region.toLowerCase().includes(q)) ||
    (l.status && l.status.toLowerCase().includes(q)) ||
    (l.followUpPerson && l.followUpPerson.toLowerCase().includes(q))
  );
});

const handleSelectLeadChange = (leadId: string) => {
  const found = (props.leads || []).find((l) => l.id === leadId);
  if (found) emit('select-lead', found);
};

const getEngineText = (engine?: string) => {
  if (!engine) return '本地大模型 (DeepSeek)';
  const lower = engine.toLowerCase();
  if (lower.includes('llm') || lower.includes('deepseek') || lower.includes('gemini') || lower.includes('qwen')) {
    return '本地大模型 (DeepSeek)';
  }
  if (lower.includes('rule') || lower.includes('template')) {
    return '规则引擎聚合';
  }
  return engine;
};

const getGradeBadgeClass = (grade?: string) => {
  switch (grade) {
    case 'A':
      return 'bg-rose-600 border border-rose-500/40 text-white';
    case 'B':
      return 'bg-amber-600 border border-amber-500/40 text-white';
    case 'C':
      return 'bg-blue-600 border border-blue-500/40 text-white';
    default:
      return 'bg-slate-700 border border-slate-600 text-white';
  }
};

const INFO_FIELD_LABELS: Record<string, string> = {
  companyBasic: '企业基本信息',
  plantScale: '厂区规模',
  treatmentProcess: '处理工艺',
  pastProjects: '过往改造项目',
  operationMode: '运维模式',
  energyLaborCost: '能耗与人工成本',
};

const infoItems = computed(() => {
  const info = props.activeReport?.aggregatedInfo || {};
  return Object.keys(INFO_FIELD_LABELS)
    .filter((k) => info[k])
    .map((k) => ({
      label: INFO_FIELD_LABELS[k],
      value: info[k]?.value ?? '',
      source: info[k]?.source ?? '',
    }));
});

const historyItems = computed(() => {
  const h = props.activeReport?.aggregatedInfo?.history;
  return Array.isArray(h) ? h : [];
});

const completenessColor = computed(() => {
  const c = props.activeReport?.completeness ?? 0;
  if (c >= 67) return 'text-emerald-500';
  if (c >= 34) return 'text-amber-500';
  return 'text-rose-500';
});

const formatTime = (iso?: string) => {
  if (!iso) return '—';
  return iso.replace('T', ' ').replace(/\+.*$/, '');
};

const exportWord = () => {
  const report = props.activeReport;
  if (!report) return;
  const company = props.selectedLead?.company || '目标企业';
  const title = props.selectedLead?.title || '预调研报告';
  const version = report.version || 1;
  const completeness = report.completeness || 0;
  const engineText = getEngineText(report.engine);
  const time = formatTime(report.createdAt);
  const content = report.reportContent || '';

  const html = `
    <html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>
    <head>
      <meta charset="utf-8">
      <title>${company} 客户预调研报告</title>
      <style>
        body { font-family: SimSun, "宋体", serif; line-height: 1.6; color: #333; }
        h1 { font-size: 18pt; text-align: center; color: #1e3a8a; }
        h2 { font-size: 14pt; color: #1e3a8a; border-bottom: 1px solid #93c5fd; padding-bottom: 4px; margin-top: 18px; }
        .meta-box { background: #f8fafc; border: 1px solid #cbd5e1; padding: 10px; margin-bottom: 15px; font-size: 10pt; }
        .meta-table { width: 100%; border-collapse: collapse; }
        .meta-table td { padding: 4px 8px; font-size: 10pt; }
        .meta-label { font-weight: bold; color: #475569; width: 90px; }
        .content { font-size: 11pt; line-height: 1.8; }
        .footer { margin-top: 30px; font-size: 9pt; color: #94a3b8; text-align: center; border-top: 1px solid #e2e8f0; padding-top: 10px; }
      </style>
    </head>
    <body>
      <h1>${company} · 客户预调研与痛点研判报告</h1>
      <div class="meta-box">
        <table class="meta-table">
          <tr>
            <td class="meta-label">标的公告：</td><td>${title}</td>
            <td class="meta-label">报告版本：</td><td>v${version}</td>
          </tr>
          <tr>
            <td class="meta-label">研判引擎：</td><td>${engineText}</td>
            <td class="meta-label">信息完整度：</td><td>${completeness}%</td>
          </tr>
          <tr>
            <td class="meta-label">生成时间：</td><td colspan="3">${time}</td>
          </tr>
        </table>
      </div>
      <h2>一、痛点研判与策略建议</h2>
      <div class="content">${content.replace(/\n/g, '<br/>')}</div>
      <div class="footer">由 污水智控·商机大脑 智能研判引擎生成 · 仅供内部商业决策参考</div>
    </body>
    </html>
  `;
  const blob = new Blob([html], { type: 'application/msword;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  const safeName = (company || '预调研报告').replace(/[\\/:*?"<>|]/g, '_');
  a.href = url;
  a.download = `${safeName}_预调研报告_v${version}.doc`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
};

const exportPdf = async () => {
  const report = props.activeReport;
  if (!report) return;
  const company = props.selectedLead?.company || '目标企业';
  const title = props.selectedLead?.title || '预调研报告';
  const version = report.version || 1;
  const completeness = report.completeness || 0;
  const engineText = getEngineText(report.engine);
  const time = formatTime(report.createdAt);
  const content = report.reportContent || '';

  // 离屏 DOM（纯内联样式，html2canvas 渲染为图片后写入 PDF）
  const el = document.createElement('div');
  el.style.position = 'absolute';
  el.style.left = '-10000px';
  el.style.top = '0';
  el.style.width = '794px';
  el.style.background = '#ffffff';
  el.innerHTML = `
    <div style="width:794px;box-sizing:border-box;padding:24px;font-family:-apple-system,'PingFang SC','Microsoft YaHei',sans-serif;line-height:1.7;color:#1e293b;">
      <h1 style="margin:0 0 16px;padding-bottom:12px;font-size:20px;color:#0f172a;text-align:center;border-bottom:3px solid #0284c7;">${company} · 客户预调研与痛点研判报告</h1>
      <table style="width:100%;border-collapse:collapse;margin-bottom:18px;background:#f8fafc;border:1px solid #e2e8f0;">
        <tr>
          <td style="width:90px;padding:7px 10px;font-size:12px;font-weight:bold;color:#64748b;border:1px solid #e2e8f0;">标的公告</td>
          <td style="padding:7px 10px;font-size:12px;border:1px solid #e2e8f0;">${title}</td>
          <td style="width:90px;padding:7px 10px;font-size:12px;font-weight:bold;color:#64748b;border:1px solid #e2e8f0;">报告版本</td>
          <td style="width:80px;padding:7px 10px;font-size:12px;border:1px solid #e2e8f0;">v${version}</td>
        </tr>
        <tr>
          <td style="padding:7px 10px;font-size:12px;font-weight:bold;color:#64748b;border:1px solid #e2e8f0;">研判引擎</td>
          <td style="padding:7px 10px;font-size:12px;border:1px solid #e2e8f0;">${engineText}</td>
          <td style="padding:7px 10px;font-size:12px;font-weight:bold;color:#64748b;border:1px solid #e2e8f0;">信息完整度</td>
          <td style="padding:7px 10px;font-size:12px;border:1px solid #e2e8f0;">${completeness}%</td>
        </tr>
        <tr>
          <td style="padding:7px 10px;font-size:12px;font-weight:bold;color:#64748b;border:1px solid #e2e8f0;">生成时间</td>
          <td colspan="3" style="padding:7px 10px;font-size:12px;border:1px solid #e2e8f0;">${time}</td>
        </tr>
      </table>
      <h2 style="margin:18px 0 8px;padding-bottom:4px;font-size:15px;color:#0369a1;border-bottom:1px solid #e2e8f0;">一、痛点研判与策略建议</h2>
      <div style="font-size:13px;line-height:1.9;white-space:pre-wrap;color:#334155;">${content}</div>
      <div style="margin-top:30px;padding-top:10px;font-size:10px;color:#94a3b8;text-align:center;border-top:1px solid #e2e8f0;">由 污水智控·商机大脑 智能研判引擎生成 · 仅供内部商业决策参考</div>
    </div>
  `;
  document.body.appendChild(el);
  try {
    await new Promise(resolve => setTimeout(resolve, 80));
    const canvas = await html2canvas(el, { scale: 2, useCORS: true, backgroundColor: '#ffffff' });
    document.body.removeChild(el);

    const pdf = new jsPDF({ unit: 'mm', format: 'a4', orientation: 'portrait' });
    const pageW = 210;
    const pageH = 297;
    const margin = 10;
    const contentH = pageH - margin * 2;
    const imgW = pageW - margin * 2;
    const imgH = (canvas.height * imgW) / canvas.width;
    const imgData = canvas.toDataURL('image/jpeg', 0.95);

    let heightLeft = imgH;
    let position = margin;
    pdf.addImage(imgData, 'JPEG', margin, position, imgW, imgH);
    heightLeft -= contentH;
    while (heightLeft > 0) {
      pdf.addPage();
      position = heightLeft - contentH;
      pdf.addImage(imgData, 'JPEG', margin, position, imgW, imgH);
      heightLeft -= contentH;
    }
    pdf.save(`${company}_预调研报告_v${version}.pdf`);
  } catch (err) {
    document.body.removeChild(el);
    console.error('PDF 导出失败:', err);
    alert('PDF 导出失败，请重试');
  }
};
</script>
