<template>
  <div class="flex-1 p-6 flex overflow-hidden gap-4">
    <!-- 左侧：竞品库列表 -->
    <div class="flex-1 flex flex-col bg-slate-950/40 border border-slate-800 rounded-2xl overflow-hidden min-w-0">
      <div class="p-4 bg-slate-950 border-b border-slate-800 flex justify-between items-center shrink-0">
        <div class="flex items-center space-x-2">
          <Layers class="h-5 w-5 text-slate-300" />
          <div>
            <h4 class="text-sm font-bold text-slate-100">竞品信息库 · AI 动态监测</h4>
            <p class="text-xs text-slate-300">人工录入竞品档案，DeepSeek 检索新品/中标/技术/报价/案例并写入详情记录。</p>
          </div>
        </div>
        <button
          v-if="currentRole !== '商务专员'"
          @click="openAdd"
          class="bg-slate-100 hover:bg-white text-slate-900 text-xs font-bold px-3.5 py-2 rounded-lg flex items-center space-x-1.5 transition border border-slate-300"
        >
          <Plus class="h-4 w-4" />
          <span>录入竞品</span>
        </button>
      </div>

      <div class="flex-1 overflow-y-auto p-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
          <div
            v-for="comp in sortedCompetitors"
            :key="comp.id"
            :class="[
              'p-4 rounded-xl border transition cursor-pointer',
              detailComp?.id === comp.id ? 'border-slate-400 bg-slate-900' : 'border-slate-800 bg-slate-950 hover:border-slate-600',
              (comp.status || 'active') !== 'active' ? 'opacity-55' : ''
            ]"
            @click="openDetail(comp)"
          >
            <div class="flex justify-between items-start mb-2">
              <h5 class="text-sm font-bold text-slate-100">{{ comp.name }}</h5>
              <div class="flex items-center gap-1 shrink-0 ml-2">
                <span v-if="comp.priority === 'key'" class="text-[9px] text-amber-300 border border-amber-600/40 bg-amber-950/30 px-1.5 py-0.5 rounded">重点</span>
                <span v-if="(comp.status || 'active') !== 'active'" class="text-[9px] text-slate-300 border border-slate-600 px-1.5 py-0.5 rounded">失效</span>
                <span v-if="intelCount(comp.monitoringIntel) > 0" class="text-[9px] text-teal-300 border border-teal-600/40 bg-teal-950/30 px-1.5 py-0.5 rounded">
                  {{ intelCount(comp.monitoringIntel) }} 条动态
                </span>
              </div>
            </div>
            <p class="text-xs text-slate-300 line-clamp-2 mb-2">{{ comp.mainBusiness || '主营业务待补充' }}</p>
            <div class="text-[10px] text-slate-400 mb-3">更新：{{ formatTime(comp.updatedAt) }}</div>
            <div class="flex items-center gap-1.5" @click.stop>
              <button
                @click="handleEnrich(comp.id)"
                :disabled="enrichingCompetitorId === comp.id"
                class="flex-1 soft-btn-primary text-xs font-semibold px-2 py-2 rounded-lg flex items-center justify-center gap-1"
              >
                <RefreshCw class="h-3.5 w-3.5" :class="enrichingCompetitorId === comp.id ? 'animate-spin' : ''" />
                <span>{{ enrichingCompetitorId === comp.id ? '检索中...' : 'AI 检索动态' }}</span>
              </button>
              <button
                v-if="currentRole !== '商务专员'"
                @click="openEdit(comp)"
                class="soft-btn text-xs px-2.5 py-2 rounded-lg"
                title="编辑"
              >
                <Pencil class="h-3.5 w-3.5" />
              </button>
              <button
                v-if="currentRole !== '商务专员'"
                @click="emit('toggle-status', { id: comp.id, status: (comp.status || 'active') === 'active' ? 'inactive' : 'active' })"
                class="soft-btn text-xs px-2.5 py-2 rounded-lg"
                :title="(comp.status || 'active') === 'active' ? '设为失效' : '恢复启用'"
              >
                <Power class="h-3.5 w-3.5" />
              </button>
              <button
                v-if="currentRole !== '商务专员'"
                @click="emit('delete-competitor', comp.id)"
                class="soft-btn text-xs px-2.5 py-2 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-rose-950/40"
                :title="(comp.status || 'active') !== 'active' ? '删除失效竞品' : '删除竞品'"
              >
                <Trash2 class="h-3.5 w-3.5" />
              </button>
              <button
                @click="openDetail(comp)"
                class="soft-btn text-xs px-2 py-2 rounded-lg flex items-center"
                title="查看详情"
              >
                <ChevronRight class="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
          <div v-if="!competitors.length" class="col-span-full p-12 text-center text-slate-400 border-2 border-dashed border-slate-700 rounded-xl">
            竞品库为空，请点击「录入竞品」开始维护。
          </div>
        </div>
      </div>
    </div>

    <!-- 右侧：竞品详情（五类动态 + 历史记录） -->
    <div class="w-[420px] shrink-0 flex flex-col bg-slate-950/40 border border-slate-800 rounded-2xl overflow-hidden">
      <div class="p-4 bg-slate-950 border-b border-slate-800 flex justify-between items-center shrink-0">
        <div class="flex items-center gap-2 min-w-0">
          <FileText class="h-4 w-4 text-slate-300 shrink-0" />
          <h4 class="text-xs font-bold text-slate-100 truncate">{{ detailComp ? detailComp.name : '竞品详情' }}</h4>
        </div>
        <button v-if="detailComp" @click="closeDetail" class="text-slate-300 hover:text-slate-200"><X class="h-4 w-4" /></button>
      </div>

      <div v-if="detailComp" class="flex-1 overflow-y-auto p-4 space-y-4">
        <!-- 基础档案 -->
        <div class="bg-slate-900 border border-slate-800 rounded-xl p-3 space-y-1.5 text-xs">
          <div class="flex justify-between items-center mb-1">
            <span class="text-slate-400 font-bold text-[10px] uppercase">基础档案</span>
            <button
              v-if="currentRole !== '商务专员'"
              @click="emit('delete-competitor', detailComp.id)"
              class="text-[10px] text-rose-400 hover:text-rose-300 flex items-center gap-1"
              title="删除该竞品"
            >
              <Trash2 class="h-3 w-3" />
              <span>删除竞品</span>
            </button>
          </div>
          <div v-if="detailComp.mainBusiness"><span class="text-slate-400">主营：</span><span class="text-slate-200">{{ detailComp.mainBusiness }}</span></div>
          <div v-if="detailComp.techRoute"><span class="text-slate-400">技术路线：</span><span class="text-slate-200">{{ detailComp.techRoute }}</span></div>
          <div v-if="detailComp.pricingRange"><span class="text-slate-400">报价：</span><span class="text-slate-200">{{ detailComp.pricingRange }}</span></div>
          <div v-if="detailComp.typicalCases"><span class="text-slate-400">案例：</span><span class="text-slate-200">{{ detailComp.typicalCases }}</span></div>
          <div v-if="detailComp.strengths?.length"><span class="text-slate-400">优势：</span><span class="text-slate-200">{{ detailComp.strengths.join('；') }}</span></div>
          <div v-if="detailComp.weaknesses?.length"><span class="text-slate-400">劣势：</span><span class="text-slate-300">{{ detailComp.weaknesses.join('；') }}</span></div>
          <div><span class="text-slate-400">最近检索：</span><span class="text-slate-300">{{ detailComp.lastEnrichedAt ? formatTime(detailComp.lastEnrichedAt) : '从未检索' }}</span></div>
        </div>

        <!-- 五类 AI 监测动态 -->
        <div class="space-y-3">
          <div class="flex justify-between items-center">
            <span class="text-xs font-bold text-slate-200">AI 监测动态</span>
            <button
              @click="handleEnrich(detailComp.id)"
              :disabled="enrichingCompetitorId === detailComp.id"
              class="text-xs soft-btn-primary px-2.5 py-1 rounded-md font-semibold"
            >
              {{ enrichingCompetitorId === detailComp.id ? '检索中...' : '重新检索' }}
            </button>
          </div>

          <div v-for="sec in INTEL_SECTIONS" :key="sec.key" class="bg-slate-900 border border-slate-800 rounded-xl p-3">
            <div class="flex justify-between items-center mb-2">
              <span class="text-xs font-bold text-slate-200">{{ sec.label }}</span>
              <span class="text-[10px] text-slate-400">{{ renderItems(detailComp.monitoringIntel?.[sec.key]).length }} 条</span>
            </div>
            <ul v-if="renderItems(detailComp.monitoringIntel?.[sec.key]).length" class="space-y-2">
              <li
                v-for="(item, idx) in renderItems(detailComp.monitoringIntel?.[sec.key])"
                :key="idx"
                class="text-[10px] border-l-2 border-teal-700 pl-2"
              >
                <div v-if="item.title" class="font-semibold text-slate-200 mb-0.5">{{ item.title }}</div>
                <p class="text-slate-300 leading-relaxed">{{ item.summary || '—' }}</p>
                <div class="flex items-center gap-2 mt-1 text-slate-400">
                  <span v-if="item.date">{{ item.date }}</span>
                  <a
                    v-if="item.source && /^https?:\/\//.test(item.source)"
                    :href="item.source"
                    target="_blank"
                    class="text-teal-400 hover:text-teal-300 flex items-center gap-0.5 truncate"
                    @click.stop
                  >
                    <LinkIcon class="h-3 w-3 shrink-0" />来源
                  </a>
                  <span v-else-if="item.source" class="truncate">来源：{{ item.source }}</span>
                </div>
              </li>
            </ul>
            <p v-else class="text-[10px] text-slate-400 italic">暂无公开信息，可点击「AI 检索动态」补充</p>
          </div>

          <div v-if="detailComp.monitoringIntel?.infoSource" class="text-[10px] text-slate-400">
            总体来源：{{ detailComp.monitoringIntel.infoSource }}
          </div>
        </div>

        <!-- 来源链接汇总 -->
        <div v-if="intelSourceLinks.length" class="bg-slate-900 border border-slate-800 rounded-xl p-3">
          <h5 class="text-xs font-bold text-slate-200 mb-2 flex items-center"><LinkIcon class="h-3.5 w-3.5 mr-1" />来源链接（{{ intelSourceLinks.length }}）</h5>
          <ul class="space-y-1">
            <li v-for="(s, i) in intelSourceLinks" :key="i" class="text-[10px]">
              <a :href="s.url" target="_blank" class="text-teal-400 hover:text-teal-300 break-all">{{ s.label }}</a>
            </li>
          </ul>
        </div>

        <!-- 检索历史 -->
        <div class="border-t border-slate-800 pt-3">
          <div class="text-xs font-bold text-slate-200 mb-2">动态更新记录</div>
          <p v-if="loadingHistory" class="text-[10px] text-slate-400">加载中...</p>
          <ul v-else-if="updateHistory.length" class="space-y-2">
            <li
              v-for="rec in updateHistory"
              :key="rec.id"
              class="bg-slate-900 border border-slate-800 rounded-lg p-2.5 text-[10px]"
            >
              <div class="flex justify-between text-slate-300 mb-1">
                <span>{{ formatTime(rec.createdAt) }}</span>
                <span class="truncate ml-2">{{ rec.source || 'DeepSeek' }}</span>
              </div>
              <div v-if="rec.intelPayload" class="space-y-1">
                <span
                  v-for="sec in INTEL_SECTIONS"
                  :key="sec.key"
                  v-show="renderItems(rec.intelPayload?.[sec.key]).length"
                  class="inline-block mr-1 mb-1 px-1.5 py-0.5 rounded bg-slate-800 text-slate-300"
                >
                  {{ sec.label }} {{ renderItems(rec.intelPayload?.[sec.key]).length }}
                </span>
              </div>
              <p v-else-if="Object.keys(rec.changedFields || {}).length" class="text-slate-300">
                更新字段：{{ Object.keys(rec.changedFields).join('、') }}
              </p>
            </li>
          </ul>
          <p v-else class="text-[10px] text-slate-400 italic">暂无检索记录</p>
        </div>
      </div>

      <div v-else class="flex-1 flex items-center justify-center p-8 text-center text-slate-400 text-xs">
        点击左侧竞品卡片查看详情<br />或使用「AI 检索动态」获取公开情报
      </div>
    </div>

    <!-- 录入 / 编辑弹层 -->
    <div v-if="showForm" class="fixed inset-0 z-50 bg-black/60 flex items-center justify-center p-6" @click.self="closeForm">
      <div class="bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-lg max-h-[88vh] overflow-y-auto">
        <div class="p-4 border-b border-slate-800 flex justify-between items-center sticky top-0 bg-slate-900">
          <h4 class="text-sm font-bold text-slate-100">{{ editingId ? '编辑竞品资料' : '录入新竞品' }}</h4>
          <button @click="closeForm" class="text-slate-300 hover:text-slate-200"><X class="h-4 w-4" /></button>
        </div>
        <div v-if="formError" class="mx-4 mt-3 p-2.5 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-400 text-xs">
          {{ formError }}
        </div>
        <div class="p-4 space-y-3">
          <div>
            <label class="text-xs text-slate-300 block mb-1">竞品名称 <span class="text-rose-400">*</span></label>
            <input v-model="form.name" type="text" class="w-full bg-slate-950 border border-slate-700 text-slate-100 rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-slate-500" />
          </div>
          <div>
            <label class="text-xs text-slate-300 block mb-1">主营业务</label>
            <input v-model="form.mainBusiness" type="text" class="w-full bg-slate-950 border border-slate-700 text-slate-100 rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-slate-500" />
          </div>
          <div>
            <label class="text-xs text-slate-300 block mb-1">技术路线</label>
            <input v-model="form.techRoute" type="text" class="w-full bg-slate-950 border border-slate-700 text-slate-100 rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-slate-500" />
          </div>
          <div>
            <label class="text-xs text-slate-300 block mb-1">报价水平</label>
            <input v-model="form.pricingRange" type="text" class="w-full bg-slate-950 border border-slate-700 text-slate-100 rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-slate-500" placeholder="如：300-800万" />
          </div>
          <div>
            <label class="text-xs text-slate-300 block mb-1">典型案例</label>
            <textarea v-model="form.typicalCases" rows="2" class="w-full bg-slate-950 border border-slate-700 text-slate-100 rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-slate-500 resize-none"></textarea>
          </div>
          <div>
            <label class="text-xs text-slate-300 block mb-1">优势（每行一条）</label>
            <textarea v-model="form.strengths" rows="2" class="w-full bg-slate-950 border border-slate-700 text-slate-100 rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-slate-500 resize-none"></textarea>
          </div>
          <div>
            <label class="text-xs text-slate-300 block mb-1">劣势（每行一条）</label>
            <textarea v-model="form.weaknesses" rows="2" class="w-full bg-slate-950 border border-slate-700 text-slate-100 rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-slate-500 resize-none"></textarea>
          </div>
          <div class="flex gap-3">
            <div class="flex-1">
              <label class="text-xs text-slate-300 block mb-1">信息来源</label>
              <input v-model="form.infoSource" type="text" class="w-full bg-slate-950 border border-slate-700 text-slate-100 rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-slate-500" />
            </div>
            <div class="w-24">
              <label class="text-xs text-slate-300 block mb-1">胜率%</label>
              <input v-model.number="form.winRate" type="number" min="0" max="100" class="w-full bg-slate-950 border border-slate-700 text-slate-100 rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-slate-500" />
            </div>
            <div class="w-24">
              <label class="text-xs text-slate-300 block mb-1">监测优先级</label>
              <select v-model="form.priority" class="w-full bg-slate-950 border border-slate-700 text-slate-100 rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-slate-500">
                <option value="normal">普通</option>
                <option value="key">重点关注</option>
              </select>
            </div>
          </div>
        </div>
        <div class="p-4 border-t border-slate-800 flex justify-end gap-2 sticky bottom-0 bg-slate-900">
          <button @click="closeForm" class="px-4 py-2 text-xs text-slate-300 hover:text-slate-100 border border-slate-600 rounded-lg">取消</button>
          <button @click="submitForm" class="bg-slate-100 hover:bg-white text-slate-900 text-xs font-bold px-4 py-2 rounded-lg border border-slate-300">{{ editingId ? '保存' : '确认录入' }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue';
import { Layers, Plus, Pencil, Power, RefreshCw, Link as LinkIcon, X, FileText, ChevronRight, Trash2 } from 'lucide-vue-next';
import { Competitor, CompetitorIntelItem, CompetitorMonitoringIntel, CompetitorUpdateRecord } from '../types';

const INTEL_SECTIONS: { key: keyof CompetitorMonitoringIntel; label: string }[] = [
  { key: 'newProducts', label: '新品发布' },
  { key: 'winningBids', label: '中标公告' },
  { key: 'techNews', label: '技术动态' },
  { key: 'pricingChanges', label: '报价调整' },
  { key: 'customerCases', label: '客户案例' },
];

const props = defineProps<{
  competitors: Competitor[];
  enrichingCompetitorId: string;
  currentRole?: string;
}>();

const emit = defineEmits<{
  (e: 'add-competitor', form: Partial<Competitor>): void;
  (e: 'update-competitor', form: Partial<Competitor> & { id: string }): void;
  (e: 'toggle-status', payload: { id: string; status: 'active' | 'inactive' }): void;
  (e: 'enrich-competitor', compId: string): void;
  (e: 'delete-competitor', compId: string): void;
}>();

const showForm = ref(false);
const editingId = ref<string | null>(null);
const formError = ref('');
const detailComp = ref<Competitor | null>(null);
const updateHistory = ref<CompetitorUpdateRecord[]>([]);
const loadingHistory = ref(false);

const form = reactive({
  name: '',
  mainBusiness: '',
  techRoute: '',
  pricingRange: '',
  typicalCases: '',
  strengths: '',
  weaknesses: '',
  infoSource: '',
  winRate: 50,
  priority: 'normal',
});

const sortedCompetitors = computed(() =>
  [...props.competitors].sort((a, b) => {
    const sa = (a.status || 'active') === 'active' ? 0 : 1;
    const sb = (b.status || 'active') === 'active' ? 0 : 1;
    return sa - sb;
  })
);

const intelCount = (intel?: CompetitorMonitoringIntel) => {
  if (!intel) return 0;
  return INTEL_SECTIONS.reduce((n, s) => n + (intel[s.key]?.length || 0), 0);
};

const intelSourceLinks = computed(() => {
  const intel = detailComp.value?.monitoringIntel;
  if (!intel) return [];
  const links: { label: string; url: string }[] = [];
  INTEL_SECTIONS.forEach((sec) => {
    (intel[sec.key] || []).forEach((item: CompetitorIntelItem) => {
      if (item.source && /^https?:\/\//.test(item.source)) {
        links.push({ label: `${sec.label}${item.title ? '·' + item.title.substring(0, 30) : ''}`, url: item.source });
      }
    });
  });
  return links;
});

const resetForm = () => {
  form.name = '';
  form.mainBusiness = '';
  form.techRoute = '';
  form.pricingRange = '';
  form.typicalCases = '';
  form.strengths = '';
  form.weaknesses = '';
  form.infoSource = '';
  form.winRate = 50;
  form.priority = 'normal';
};

const openAdd = () => {
  editingId.value = null;
  resetForm();
  showForm.value = true;
};

const openEdit = (c: Competitor) => {
  editingId.value = c.id;
  form.name = c.name || '';
  form.mainBusiness = c.mainBusiness || '';
  form.techRoute = c.techRoute || '';
  form.pricingRange = c.pricingRange || '';
  form.typicalCases = c.typicalCases || '';
  form.strengths = (c.strengths || []).join('\n');
  form.weaknesses = (c.weaknesses || []).join('\n');
  form.infoSource = c.infoSource || '';
  form.winRate = c.winRate ?? 50;
  form.priority = c.priority || 'normal';
  showForm.value = true;
};

const closeForm = () => {
  showForm.value = false;
  editingId.value = null;
};

const splitLines = (raw: string): string[] =>
  raw.split(/[\n,，;；]/).map((s) => s.trim()).filter(Boolean);

const submitForm = () => {
  formError.value = '';
  if (!form.name.trim()) {
    formError.value = '请填写竞品名称';
    return;
  }
  const payload: Partial<Competitor> = {
    name: form.name.trim(),
    mainBusiness: form.mainBusiness.trim(),
    techRoute: form.techRoute.trim(),
    pricingRange: form.pricingRange.trim(),
    typicalCases: form.typicalCases.trim(),
    strengths: splitLines(form.strengths),
    weaknesses: splitLines(form.weaknesses),
    infoSource: form.infoSource.trim(),
    winRate: Number(form.winRate) || 0,
    priority: form.priority,
  };
  if (editingId.value) {
    emit('update-competitor', { ...payload, id: editingId.value });
  } else {
    emit('add-competitor', payload);
  }
  closeForm();
};

const formatTime = (iso?: string | null) => {
  if (!iso) return '未更新';
  return iso.replace('T', ' ').replace(/\+.*$/, '');
};

const loadHistory = async (compId: string) => {
  loadingHistory.value = true;
  try {
    const res = await fetch(`/api/competitors/${compId}/updates`);
    if (res.ok) updateHistory.value = await res.json();
    else updateHistory.value = [];
  } catch {
    updateHistory.value = [];
  } finally {
    loadingHistory.value = false;
  }
};

const openDetail = async (c: Competitor) => {
  detailComp.value = c;
  await loadHistory(c.id);
};

const closeDetail = () => {
  detailComp.value = null;
  updateHistory.value = [];
};

const refreshDetailComp = async () => {
  if (!detailComp.value) return;
  const latest = props.competitors.find((c) => c.id === detailComp.value!.id);
  if (latest) {
    detailComp.value = latest;
    await loadHistory(latest.id);
  }
};

const handleEnrich = (compId: string) => {
  emit('enrich-competitor', compId);
};

defineExpose({ refreshDetailComp, openDetailById: (id: string) => {
  const c = props.competitors.find((x) => x.id === id);
  if (c) openDetail(c);
}});

const renderItems = (items?: CompetitorIntelItem[]) => items || [];
</script>