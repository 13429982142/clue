<template>
  <div class="flex-1 p-8 overflow-y-auto space-y-6 max-w-4xl mx-auto">
    <div class="bg-slate-950 p-6 rounded-2xl border border-slate-800 space-y-4">
      <div class="flex items-center space-x-2">
        <Sliders class="h-5 w-5 text-cyan-400" />
        <h3 class="text-lg font-bold">5维打分配置中心</h3>
      </div>
      <p class="text-xs text-slate-300 leading-relaxed">
        系统提取全网招采和项目数据后，会根据以下5大权重参数计算加权综合分，并自动切分分级。
        <strong class="text-rose-400 block mt-1">注意：总权重必须相加等于 100%。修改后系统将实时自动重新计算所有的商机，且进行审计归案存档。</strong>
      </p>

      <div class="space-y-4 pt-4 border-t border-slate-900">
        <!-- 预算规模要素滑块 -->
        <div class="space-y-1">
          <div class="flex justify-between text-xs">
            <span class="font-semibold">1. 项目预算权重 (%)</span>
            <span class="font-mono text-cyan-400">{{ safeRule.budgetWeight }}%</span>
          </div>
          <input 
            type="range"
            min="0"
            max="100"
            step="5"
            :value="safeRule.budgetWeight"
            @input="handleUpdate('budgetWeight', Number(($event.target as HTMLInputElement).value))"
            class="score-slider w-full"
            :style="fillStyle(safeRule.budgetWeight)"
          />
          <p class="text-xs text-slate-400">（根据预估标的金额分阶估算：500万及以上20分、200-500万15分、100-200万10分、100万以下5分）</p>
        </div>

        <!-- 需求匹配度要素滑块 -->
        <div class="space-y-1">
          <div class="flex justify-between text-xs">
            <span class="font-semibold">2. 需求匹配度权重 (%)</span>
            <span class="font-mono text-cyan-400">{{ safeRule.matchWeight }}%</span>
          </div>
          <input 
            type="range"
            min="0"
            max="100"
            step="5"
            :value="safeRule.matchWeight"
            @input="handleUpdate('matchWeight', Number(($event.target as HTMLInputElement).value))"
            class="score-slider w-full"
            :style="fillStyle(safeRule.matchWeight)"
          />
          <p class="text-xs text-slate-400">（完全匹配核心业务30分、部分匹配20分、关联度低10分）</p>
        </div>

        <!-- Qualification element slider -->
        <div class="space-y-1">
          <div class="flex justify-between text-xs">
            <span class="font-semibold">3. 项目阶段权重 (%)</span>
            <span class="font-mono text-cyan-400">{{ safeRule.stageWeight }}%</span>
          </div>
          <input 
            type="range"
            min="0"
            max="100"
            step="5"
            :value="safeRule.stageWeight"
            @input="handleUpdate('stageWeight', Number(($event.target as HTMLInputElement).value))"
            class="score-slider w-full"
            :style="fillStyle(safeRule.stageWeight)"
          />
          <p class="text-xs text-slate-400">（已发布招标公告25分、意向征集/可研15分、规划阶段5分）</p>
        </div>

        <!-- 客户资质要素滑块 -->
        <div class="space-y-1">
          <div class="flex justify-between text-xs">
            <span class="font-semibold">4. 客户资质权重 (%)</span>
            <span class="font-mono text-cyan-400">{{ safeRule.qualificationWeight }}%</span>
          </div>
          <input 
            type="range"
            min="0"
            max="100"
            step="5"
            :value="safeRule.qualificationWeight"
            @input="handleUpdate('qualificationWeight', Number(($event.target as HTMLInputElement).value))"
            class="score-slider w-full"
            :style="fillStyle(safeRule.qualificationWeight)"
          />
          <p class="text-xs text-slate-400">（国企/事业单位/上市水务15分、规模民企10分、小型客户5分）</p>
        </div>

        <!-- 地域匹配要素滑块 -->
        <div class="space-y-1">
          <div class="flex justify-between text-xs">
            <span class="font-semibold">5. 地域匹配权重 (%)</span>
            <span class="font-mono text-cyan-400">{{ safeRule.regionWeight }}%</span>
          </div>
          <input 
            type="range"
            min="0"
            max="100"
            step="5"
            :value="safeRule.regionWeight"
            @input="handleUpdate('regionWeight', Number(($event.target as HTMLInputElement).value))"
            class="score-slider w-full"
            :style="fillStyle(safeRule.regionWeight)"
          />
          <p class="text-xs text-slate-400">（核心服务区域10分、外围区域5分）</p>
        </div>
      </div>

      <div class="mt-4 pt-4 border-t border-slate-900 flex justify-between items-center text-xs">
        <div>
          <span class="text-slate-300">当前公式累计总和：</span>
          <span :class="totalWeight === 100 ? 'text-emerald-400 font-mono font-bold text-sm' : 'text-rose-400 font-mono font-bold text-sm'">
            {{ totalWeight }}%
          </span>
          <span v-if="totalWeight !== 100" class="text-rose-400 block text-xs">⚠️ 核心错误：总权重不等于100%，将导致估分规则偏倚！</span>
        </div>

        <div class="flex items-center space-x-2">
          <span class="text-slate-300">高价值预警阈值（分）：</span>
          <input 
            type="number" 
            min="40"
            max="95"
            :value="safeRule.warningThreshold"
            @input="handleUpdate('warningThreshold', Number(($event.target as HTMLInputElement).value))"
            class="bg-slate-900 border border-slate-800 rounded-lg px-2 py-1 w-16 text-center font-bold text-amber-400 text-xs focus:outline-none"
          />
        </div>
      </div>
    </div>

    <!-- 保存按钮（吸底固定，始终可见） -->
    <div class="sticky bottom-0 bg-slate-950/95 backdrop-blur border border-slate-800 rounded-2xl px-6 py-4 flex items-center justify-between gap-3 shadow-lg">
      <div class="text-xs">
        <span v-if="saveError" class="text-rose-400">⚠️ {{ saveError }}</span>
        <span v-else-if="savedOk" class="text-emerald-400 font-bold">✓ 保存成功，已触发增量重算</span>
        <span v-else-if="totalWeight !== 100" class="text-rose-400">总权重需等于 100% 才能保存</span>
        <span v-else class="text-slate-400">权重设置有效，可以保存</span>
      </div>
      <button
        @click="handleSave"
        :disabled="totalWeight !== 100 || saving"
        class="shrink-0 bg-cyan-600 hover:bg-cyan-500 disabled:opacity-40 text-white text-xs font-bold px-8 py-2.5 rounded-xl transition disabled:cursor-not-allowed"
      >
        {{ saving ? '保存中...' : savedOk ? '✓ 已保存' : '保存配置' }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Sliders } from 'lucide-vue-next';
import { computed, ref, watch } from 'vue';
import { ScoringRule } from '../types';

const props = defineProps<{
  scoringRule: ScoringRule;
}>();

const emit = defineEmits<{
  (e: 'update-weights', payload: Partial<ScoringRule>): Promise<boolean> | void;
}>();

const handleUpdate = (field: keyof ScoringRule, value: number) => {
  localRule.value = {
    ...localRule.value,
    [field]: value,
  };
};

// 滑块填充进度样式（min=0, max=100）
const fillStyle = (value: number) => {
  const pct = Math.min(100, Math.max(0, Number(value) || 0));
  return { '--fill': `${pct}%` } as Record<string, string>;
};

const saving = ref(false);
const saveError = ref('');
const savedOk = ref(false);
let savedTimer: ReturnType<typeof setTimeout> | null = null;

const handleSave = async () => {
  if (totalWeight.value !== 100) return;
  saving.value = true;
  saveError.value = '';
  savedOk.value = false;
  try {
    const result = await emit('update-weights', { ...localRule.value });
    if (result === false) {
      saveError.value = '保存失败，请稍后重试';
    } else {
      savedOk.value = true;
      if (savedTimer) clearTimeout(savedTimer);
      savedTimer = setTimeout(() => {
        savedOk.value = false;
      }, 3000);
    }
  } finally {
    saving.value = false;
  }
};

const normalizeRule = (rule?: Partial<ScoringRule>): ScoringRule => ({
  budgetWeight: Number(rule?.budgetWeight ?? 20),
  matchWeight: Number(rule?.matchWeight ?? 30),
  qualificationWeight: Number(rule?.qualificationWeight ?? 25),
  stageWeight: Number(rule?.stageWeight ?? 15),
  regionWeight: Number(rule?.regionWeight ?? 10),
  warningThreshold: Number(rule?.warningThreshold ?? 80),
});

const localRule = ref<ScoringRule>(normalizeRule(props.scoringRule));

watch(
  () => props.scoringRule,
  (newRule) => {
    localRule.value = normalizeRule(newRule);
  },
  { deep: true, immediate: true }
);

const safeRule = computed<ScoringRule>(() => normalizeRule(localRule.value));

const totalWeight = computed(() => {
  return (
    safeRule.value.budgetWeight +
    safeRule.value.matchWeight +
    safeRule.value.qualificationWeight +
    safeRule.value.stageWeight +
    safeRule.value.regionWeight
  );
});
</script>