<template>
  <div class="flex-1 p-8 overflow-y-auto space-y-6 max-w-5xl mx-auto w-full">
    
    <!-- Header overview card -->
    <div class="soft-panel-strong bg-gradient-to-r from-slate-900 via-slate-950 to-slate-900 border border-slate-800 p-6 rounded-2xl flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
      <div>
        <div class="flex items-center space-x-2.5">
          <div class="bg-amber-500/10 p-2 rounded-xl text-amber-400 border border-amber-500/20">
            <Search class="h-5 w-5" />
          </div>
          <div>
            <h2 class="text-lg font-bold text-slate-100">商机智能监测与网监抓取规则配置舱</h2>
            <p class="text-xs text-slate-300">精确配置监测过滤规则，配合底座 AI 引擎实现垂直招采信息流无损提炼与自动化归档。</p>
          </div>
        </div>
      </div>

      <div class="flex gap-3">
        <button 
          @click="emit('trigger-mining')"
          :disabled="isMining"
          class="bg-blue-600 hover:bg-blue-500 active:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white text-xs font-bold px-4 py-2.5 rounded-xl flex items-center space-x-1.5 transition shadow-md shadow-blue-900/30"
        >
          <span v-if="isMining" class="animate-spin inline-block h-3 w-3 border-b-2 border-white rounded-full mr-1"></span>
          <span>{{ isMining ? '智能体抓取排渣中...' : '测试抓取与配额验证' }}</span>
        </button>
      </div>
    </div>

    <!-- 动态运行时的子状态提示 -->
    <div v-if="isMining" class="soft-panel bg-slate-950 border border-cyan-500/30 p-4 rounded-xl space-y-2.5 animate-pulse">
      <div class="flex items-center space-x-2 text-cyan-400 text-xs font-bold">
        <span class="block w-2.5 h-2.5 rounded-full bg-cyan-400 animate-ping"></span>
        <span>自动化监测探针运行中：</span>
      </div>
      <p class="text-xs text-slate-300 font-mono pl-4">→ {{ miningStatus }}</p>
    </div>

    <!-- Main Configuration Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
      
      <!-- 左列：数据源和关键词（8列） -->
      <div class="lg:col-span-8 space-y-6">
        
        <!-- 第1部分：监控数据源卡片 -->
        <div class="soft-panel bg-slate-950 p-6 rounded-2xl border border-slate-800/80 space-y-4">
          <div class="flex items-center space-x-2 border-b border-slate-900 pb-3">
            <Database class="h-4.5 w-4.5 text-cyan-400" />
            <h3 class="text-sm font-bold text-slate-200">1. 网监数据源白名单配置</h3>
          </div>

          <p class="text-xs text-slate-300 leading-relaxed">
            系统在爬取和检索时会定向扫描勾选的招采公开网。您可以勾选平台提供的高信誉核心源，或自定义新增外部合法公开数据站。
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-3 pt-2">
            <label 
              v-for="source in defaultMoniSources"
              :key="source" 
              :class="[
                'flex items-center space-x-3 p-3 rounded-xl border transition cursor-pointer select-none',
                (searchConfig.monitorSources || []).includes(source) 
                  ? 'bg-cyan-500/10 border-cyan-500/40 text-slate-900' 
                  : 'bg-slate-100 border-slate-300 text-slate-900 hover:border-slate-400'
              ]"
            >
              <input 
                type="checkbox" 
                :checked="(searchConfig.monitorSources || []).includes(source)" 
                @change="toggleSource(source)"
                class="rounded text-cyan-500 focus:ring-cyan-500 bg-slate-950 border-slate-800"
              />
              <div class="text-xs">
                <span class="font-semibold block text-slate-900" style="color:#0f172a !important">{{ source }}</span>
                <span class="text-xs text-slate-600" style="color:#475569 !important">
                  <template v-if="source === '中国政府采购网'">全国政企一揽子采购标讯底座</template>
                  <template v-else-if="source === '全国公共资源交易平台'">工程总承包及机电物料高频标段网</template>
                  <template v-else-if="source === '湖北省公共资源交易云平台'">湖北招采全文检索全量标讯源</template>
                </span>
              </div>
            </label>
          </div>

          <!-- Custom Open Data Sources input -->
          <div class="pt-3 border-t border-slate-900/60 flex flex-col gap-2">
            <label class="text-xs text-slate-300 font-semibold block">新增合规公开数据源 (URL或源全名称):</label>
            <div class="flex gap-2">
              <input 
                type="text" 
                v-model="newSource"
                placeholder="如：https://www.ccgp.gov.cn/cggg/dfgg/gkzb/"
                @keydown.enter="handleAddCustomSource"
                class="soft-input bg-slate-900 border border-slate-800/80 rounded-xl px-3 py-2 text-xs flex-1 text-slate-200 placeholder-slate-600 focus:outline-none focus:ring-1 focus:ring-cyan-500"
              />
              <button 
                type="button" 
                @click="handleAddCustomSource"
                class="soft-btn bg-slate-800 hover:bg-slate-755 border border-slate-700 hover:border-slate-600 px-3 py-2 rounded-xl text-xs flex items-center space-x-1.5 transition text-slate-300 font-bold"
              >
                <span>新增数据源</span>
              </button>
            </div>

            <!-- 自定义源列表展示 -->
            <div v-if="(searchConfig.monitorSources || []).filter(s => !defaultMoniSources.includes(s)).length > 0" class="pt-2">
              <span class="text-xs text-slate-400 block mb-1.5">自定义已加过滤源:</span>
              <div class="flex flex-wrap gap-1.5">
                <span 
                  v-for="cs in (searchConfig.monitorSources || []).filter(s => !defaultMoniSources.includes(s))"
                  :key="cs" 
                  class="flex items-center space-x-1 py-1 px-2.5 rounded-lg text-[10px] font-mono bg-cyan-950/40 border border-cyan-800/40 text-cyan-300"
                >
                  <span>{{ cs }}</span>
                  <button 
                    @click="handleRemoveCustomSource(cs)"
                    class="text-rose-400 hover:text-rose-500 font-bold ml-1 text-xs"
                    title="删除该自定义源"
                  >
                    ×
                  </button>
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- SECTION 2: KEYWORDS CARD -->
        <div class="soft-panel bg-slate-950 p-6 rounded-2xl border border-slate-800/80 space-y-4">
          <div class="flex items-center space-x-2 border-b border-slate-900 pb-3">
            <Sliders class="h-4.5 w-4.5 text-amber-400" />
            <h3 class="text-sm font-bold text-slate-200">2. 自定义匹配关键词词库管理</h3>
          </div>

          <p class="text-xs text-slate-300 leading-relaxed">
            智能体爬虫获取项目详情内容后，将进行双向语言分析。只有命中了**核心包含词**且未命中**排除黑名单词**的项目才会入库，确保项目流转符合污水厂、楼宇等高智能化工艺门槛。
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            
            <!-- 核心匹配关键词块 -->
            <div class="soft-panel-inner bg-slate-900/20 border border-slate-850 p-4.5 rounded-xl space-y-3">
              <span class="text-xs font-bold text-emerald-400 flex items-center space-x-1">
                <span class="block w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                <span>A. 核心主监控词</span>
              </span>

              <div class="flex gap-1.5">
                <input 
                  type="text" 
                  v-model="newKeyword"
                  placeholder="添加包含词..."
                  @keydown.enter="handleAddKeyword"
                  class="soft-input bg-slate-950 border border-slate-800 rounded-lg px-2 py-1 text-xs flex-1 text-slate-200 placeholder-slate-600 focus:outline-none focus:ring-1 focus:ring-emerald-500"
                />
                <button 
                  @click="handleAddKeyword"
                  class="soft-btn-success bg-emerald-600 hover:bg-emerald-500 rounded-lg px-2.5 py-1 text-xs font-bold text-slate-100 transition"
                >
                  +
                </button>
              </div>

              <div class="flex flex-wrap gap-1.5 max-h-[160px] overflow-y-auto pt-1">
                <span 
                  v-for="kw in (searchConfig.keywords || [])"
                  :key="kw" 
                  class="flex items-center space-x-1 px-2 py-1 bg-emerald-800/60 border border-emerald-600/70 rounded-lg text-xs text-emerald-100 font-bold"
                >
                  <span>{{ kw }}</span>
                  <button @click="handleRemoveKeyword(kw)" class="text-rose-400 hover:text-rose-500 font-bold ml-1 text-xs">×</button>
                </span>
                <span v-if="!(searchConfig.keywords && searchConfig.keywords.length > 0)" class="text-xs text-slate-500 italic">暂无包含限制</span>
              </div>
            </div>

            <!-- 排除关键词黑名单块 -->
            <div class="soft-panel-inner bg-slate-900/20 border border-slate-850 p-4.5 rounded-xl space-y-3">
              <span class="text-xs font-bold text-rose-400 flex items-center space-x-1">
                <span class="block w-1.5 h-1.5 rounded-full bg-rose-400"></span>
                <span>B. 负向强制排除黑名单</span>
              </span>

              <div class="flex gap-1.5">
                <input 
                  type="text" 
                  v-model="newExcludeKeyword"
                  placeholder="排除项目..."
                  @keydown.enter="handleAddExclude"
                  class="soft-input bg-slate-950 border border-slate-800 rounded-lg px-2 py-1 text-xs flex-1 text-slate-200 placeholder-slate-600 focus:outline-none focus:ring-1 focus:ring-rose-500"
                />
                <button 
                  @click="handleAddExclude"
                  class="soft-btn-danger bg-rose-900/40 hover:bg-rose-900/60 border border-rose-800 rounded-lg px-2.5 py-1 text-xs font-bold text-slate-200 transition"
                >
                  +
                </button>
              </div>

              <div class="flex flex-wrap gap-1.5 max-h-[160px] overflow-y-auto pt-1">
                <span 
                  v-for="ek in (searchConfig.excludeKeywords || [])"
                  :key="ek" 
                  class="flex items-center space-x-1 px-2 py-1 bg-rose-800/60 border border-rose-600/70 rounded-lg text-xs text-rose-100 font-bold"
                >
                  <span>{{ ek }}</span>
                  <button @click="handleRemoveExclude(ek)" class="text-rose-400 hover:text-rose-500 font-bold ml-1 text-xs">×</button>
                </span>
                <span v-if="!(searchConfig.excludeKeywords && searchConfig.excludeKeywords.length > 0)" class="text-xs text-slate-500 italic">暂无黑名单排除词</span>
              </div>
            </div>

          </div>
        </div>

      </div>

      <!-- 右列：筛选维度和通用配置（4列） -->
      <div class="lg:col-span-4 space-y-6">
        
        <!-- 第3部分：筛选维度 -->
        <div class="soft-panel bg-slate-950 p-6 rounded-2xl border border-slate-800/80 space-y-5">
          <div class="flex items-center space-x-2 border-b border-slate-900 pb-3">
            <Filter class="h-4.5 w-4.5 text-cyan-400" />
            <h3 class="text-sm font-bold text-slate-200">3. 招采工程多维筛选限制</h3>
          </div>

          <div class="space-y-1.5 pt-1">
            <label class="text-xs text-slate-300 block font-semibold">
              <span>项目核算概算金额 (预算范围)</span>
            </label>
            <div class="grid grid-cols-2 gap-2">
              <div class="relative">
                <input 
                  type="number" 
                  min="0"
                  :value="searchConfig.budgetMin !== undefined ? searchConfig.budgetMin : 0"
                  @input="emit('update-config', { budgetMin: Number(($event.target as HTMLInputElement).value) })"
                  class="soft-input bg-slate-900 border border-slate-800 text-slate-200 text-xs font-mono rounded-xl p-2.5 w-full pr-8 focus:outline-none"
                  placeholder="下限"
                />
                <span class="absolute right-3 top-2.5 text-[10px] text-slate-400">万</span>
              </div>
              <div class="relative">
                <input 
                  type="number" 
                  min="0"
                  :value="searchConfig.budgetMax !== undefined ? searchConfig.budgetMax : 2000"
                  @input="emit('update-config', { budgetMax: Number(($event.target as HTMLInputElement).value) })"
                  class="soft-input bg-slate-900 border border-slate-800 text-slate-200 text-xs font-mono rounded-xl p-2.5 w-full pr-8 focus:outline-none"
                  placeholder="上限"
                />
                <span class="absolute right-3 top-2.5 text-[10px] text-slate-400">万</span>
              </div>
            </div>
            <span class="text-xs text-slate-400 block">（限制在采购金额概算：万元。如50万-1500万，有助于过滤微小件及非标）</span>
          </div>

          <div class="space-y-1.5 pt-2 border-t border-slate-900/60">
            <label class="text-xs text-slate-300 block font-semibold">公告发布时间范围</label>
            <select
              :value="searchConfig.timeRange || '不限'"
              @change="emit('update-config', { timeRange: ($event.target as HTMLSelectElement).value })"
              class="soft-input bg-slate-900 text-xs w-full text-slate-300 py-2.5 px-3 rounded-xl border border-slate-800 focus:outline-none focus:border-cyan-500"
            >
              <option value="不限">不限</option>
              <option value="近三天">近三天</option>
              <option value="近一周">近一周</option>
              <option value="近一月">近一月</option>
              <option value="近三月">近三月</option>
            </select>
            <span class="text-xs text-slate-400 block leading-relaxed">
              抓取时仅保留落在该时间窗内的公告；搜索框型源（如湖北云平台）会同步传入站点。
            </span>
          </div>

        </div>

        <!-- FREQUENCY AND OPERATIONAL ASSISTANCE -->
        <div class="soft-panel bg-slate-950 p-6 rounded-2xl border border-slate-800/80 space-y-4">
          <div class="flex items-center space-x-2">
            <Clock class="h-4 w-4 text-cyan-400" />
            <h4 class="text-xs font-bold text-slate-200">网监自动巡检频率及持久层同步</h4>
          </div>

          <div class="space-y-2">
            <select 
              :value="searchConfig.frequency"
              @change="emit('update-config', { frequency: ($event.target as HTMLSelectElement).value })"
              class="soft-input bg-slate-900 text-xs w-full text-slate-300 py-2.5 px-3 rounded-xl border border-slate-800 focus:outline-none focus:border-cyan-500"
            >
              <option value="每小时自动巡检实时">每小时自动巡检实时 (高频极敏)</option>
              <option value="每天早上8:00实时">每天早上8:00实时 (常规日更)</option>
              <option value="半天深度巡检一轮">半天深度巡检一轮 (中等循环分批)</option>
              <option value="每周一网监批量巡更">每周一网监批量巡更 (底价周更)</option>
            </select>
            <span class="text-xs text-slate-400 block leading-relaxed">定义爬虫定时扫描公网招采平台的同步轮次。</span>
          </div>

          <!-- 连接状态日志 -->
          <div class="soft-panel-muted bg-slate-900/40 p-3 rounded-xl border border-slate-850 text-xs text-slate-300 leading-relaxed font-mono">
            <p>
              <strong>当前过滤词数:</strong> {{ searchConfig.keywords ? searchConfig.keywords.length : 0 }} 核心包含 / {{ searchConfig.excludeKeywords ? searchConfig.excludeKeywords.length : 0 }} 黑名单排除<br />
              <strong>时间窗:</strong> {{ searchConfig.timeRange || '不限' }} · <strong>预算:</strong> {{ searchConfig.budgetMin ?? 0 }}-{{ searchConfig.budgetMax ?? 2000 }} 万
            </p>
          </div>
        </div>

      </div>

    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, defineProps, defineEmits } from 'vue';
import { Database, Sliders, Plus, Search, Filter, Clock } from 'lucide-vue-next';
import { SearchConfig } from '../types';

const props = defineProps<{
  searchConfig: SearchConfig;
  searchConfigStats: {
    keywordCount: number;
    matchedLeadsCount: number;
  };
  isMining: boolean;
  miningStatus: string;
}>();

const emit = defineEmits<{
  (e: 'update-config', payload: Partial<SearchConfig>): void;
  (e: 'trigger-mining'): void;
}>();

const newSource = ref('');
const newKeyword = ref('');
const newExcludeKeyword = ref('');

const defaultMoniSources = ['中国政府采购网', '全国公共资源交易平台', '湖北省公共资源交易云平台'];

const toggleSource = (source: string) => {
  const current = props.searchConfig.monitorSources || [];
  const updated = current.includes(source)
    ? current.filter((s: string) => s !== source)
    : [...current, source];
  emit('update-config', { monitorSources: updated });
};

const handleAddCustomSource = () => {
  if (!newSource.value.trim()) return;
  const current = props.searchConfig.monitorSources || [];
  if (current.includes(newSource.value.trim())) {
    newSource.value = '';
    return;
  }
  emit('update-config', { monitorSources: [...current, newSource.value.trim()] });
  newSource.value = '';
};

const handleRemoveCustomSource = (source: string) => {
  const current = props.searchConfig.monitorSources || [];
  emit('update-config', { monitorSources: current.filter((s: string) => s !== source) });
};

const handleAddKeyword = () => {
  if (!newKeyword.value.trim()) return;
  const current = props.searchConfig.keywords || [];
  if (current.includes(newKeyword.value.trim())) {
    alert('该包含词已存在，请勿重复添加');
    return;
  }
  emit('update-config', { keywords: [...current, newKeyword.value.trim()] });
  newKeyword.value = '';
};

const handleRemoveKeyword = (kw: string) => {
  const current = props.searchConfig.keywords || [];
  emit('update-config', { keywords: current.filter((k: string) => k !== kw) });
};

const handleAddExclude = () => {
  if (!newExcludeKeyword.value.trim()) return;
  const current = props.searchConfig.excludeKeywords || [];
  if (current.includes(newExcludeKeyword.value.trim())) {
    alert('该黑名单词已存在，请勿重复添加');
    return;
  }
  emit('update-config', { excludeKeywords: [...current, newExcludeKeyword.value.trim()] });
  newExcludeKeyword.value = '';
};

const handleRemoveExclude = (kw: string) => {
  const current = props.searchConfig.excludeKeywords || [];
  emit('update-config', { excludeKeywords: current.filter((k: string) => k !== kw) });
};

const togglePurchaseType = (type: string) => {
  const current = props.searchConfig.purchaseTypes || [];
  const updated = current.includes(type)
    ? current.filter((t: string) => t !== type)
    : [...current, type];
  emit('update-config', { purchaseTypes: updated });
};
</script>