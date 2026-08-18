<template>
  <div class="flex-1 p-8 overflow-y-auto max-w-5xl mx-auto w-full space-y-6">
    <!-- 头部 -->
    <div class="soft-panel-strong bg-gradient-to-r from-sky-50 via-white to-sky-50 border border-sky-200 p-6 rounded-2xl flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div class="bg-emerald-100 p-2 rounded-xl text-emerald-600 border border-emerald-200">
          <Activity class="h-5 w-5" />
        </div>
        <div>
          <h2 class="text-lg font-bold text-slate-800">数据源健康监控</h2>
          <p class="text-xs text-slate-400">仅展示网监白名单中当前配置的数据源</p>
        </div>
      </div>
      <button 
        @click="fetchSourceHealth"
        class="bg-white hover:bg-sky-50 border border-sky-300 text-sky-600 text-xs px-3 py-2 rounded-xl flex items-center gap-1.5 transition"
      >
        <RefreshCw :class="['h-3 w-3', loading ? 'animate-spin' : '']" />
        <span>刷新</span>
      </button>
    </div>

    <!-- 加载中 -->
    <div v-if="loading" class="text-center py-12 text-slate-400">
      <div class="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-sky-400 mb-3"></div>
      <p class="text-xs">加载数据源状态...</p>
    </div>

    <!-- 数据源列表 -->
    <div v-else-if="sourceHealthList.length === 0" class="text-center py-16 text-slate-400 text-sm">
      <Database class="h-10 w-10 mx-auto mb-3 text-slate-300" />
      <p>暂无数据源记录</p>
    </div>

    <div v-else class="space-y-3">
      <div
        v-for="item in sourceHealthList"
        :key="item.source"
        class="soft-panel bg-white border border-slate-200 rounded-xl p-5 flex items-start justify-between gap-4"
      >
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2 mb-2">
            <Database class="h-4 w-4 text-sky-500 shrink-0" />
            <span class="font-semibold text-slate-800 text-sm truncate">{{ item.source }}</span>
            <span
              :class="['text-[10px] px-2 py-0.5 rounded-full font-medium', statusConfig[item.status]?.bg, statusConfig[item.status]?.color]"
            >
              {{ statusConfig[item.status]?.label || item.status }}
            </span>
          </div>

          <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs text-slate-400">
            <div>
              <span class="text-slate-300">连续失败</span>
              <p class="font-medium text-slate-700">{{ item.consecutiveFailures }} 次</p>
            </div>
            <div>
              <span class="text-slate-300">总抓取</span>
              <p class="font-medium text-slate-700">{{ item.totalFetches }} 次</p>
            </div>
            <div>
              <span class="text-slate-300">最近成功</span>
              <p class="font-medium text-slate-700">{{ formatCSTDisplay(item.lastSuccessAt) }}</p>
            </div>
            <div>
              <span class="text-slate-300">最近失败</span>
              <p class="font-medium text-slate-700">{{ formatCSTDisplay(item.lastFailureAt) }}</p>
            </div>
          </div>

          <div v-if="shouldShowAlerts(item) && item.structureChangeDetected" class="mt-3 flex items-start gap-2 text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded-lg px-3 py-2">
            <AlertTriangle class="h-3.5 w-3.5 shrink-0 mt-0.5" />
            <span>页面结构可能已变更，请前往「网监抓取黑白名单」重新配置地址</span>
          </div>

          <div v-if="shouldShowAlerts(item) && item.lastErrorMessage" class="mt-2 text-xs text-red-600 bg-red-50 border border-red-100 rounded-lg px-3 py-2">
            {{ item.lastErrorMessage }}
          </div>
        </div>

        <button
          v-if="currentRole === '超级管理员' && item.status !== 'healthy'"
          @click="handleReset(item.source)"
          class="shrink-0 text-xs px-3 py-1.5 rounded-lg border border-slate-200 text-slate-500 hover:bg-slate-50 flex items-center gap-1"
        >
          <ShieldCheck class="h-3 w-3" />
          重置
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue';
import { Database, ShieldCheck, AlertTriangle, RefreshCw, Activity } from 'lucide-vue-next';
import { SourceHealth } from '../types';
import { formatCSTDisplay, isLatestEventSuccess } from '../services/timeUtil';

const props = defineProps<{
  currentRole: string;
  operatorName: string;
  /** 当前网监白名单中的数据源，用于过滤健康监控列表 */
  monitorSources: string[];
}>();

const sourceHealthList = ref<SourceHealth[]>([]);
const loading = ref(false);

const fetchSourceHealth = async () => {
  loading.value = true;
  try {
    const res = await fetch('/api/source-health/sync', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sources: props.monitorSources || [] }),
    });
    if (res.ok) {
      sourceHealthList.value = await res.json();
    }
  } catch (err) {
    console.error('Fetch source health error:', err);
  } finally {
    loading.value = false;
  }
};

const handleReset = async (source: string) => {
  try {
    const res = await fetch(`/api/source-health/${encodeURIComponent(source)}/reset`, { method: 'POST' });
    if (res.ok) {
      await fetchSourceHealth();
    }
  } catch (err) {
    console.error(err);
  }
};

const statusConfig: Record<string, { color: string; bg: string; label: string }> = {
  healthy: { color: 'text-emerald-700', bg: 'bg-emerald-100', label: '运行正常' },
  degraded: { color: 'text-amber-700', bg: 'bg-amber-100', label: '降级中' },
  abnormal: { color: 'text-red-700', bg: 'bg-red-100', label: '异常' },
};

const shouldShowAlerts = (item: SourceHealth) =>
  !isLatestEventSuccess(item.lastSuccessAt, item.lastFailureAt);

onMounted(fetchSourceHealth);
watch(() => props.monitorSources, fetchSourceHealth, { deep: true });
</script>