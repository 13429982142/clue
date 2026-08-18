<template>
  <div class="flex-1 p-8 overflow-y-auto max-w-5xl mx-auto w-full space-y-6">
    <!-- 头部 -->
    <div class="soft-panel-strong bg-gradient-to-r from-slate-900 via-slate-950 to-slate-900 border border-slate-800 p-6 rounded-2xl flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div class="bg-amber-500/10 p-2 rounded-xl text-amber-400 border border-amber-500/20">
          <Sliders class="h-5 w-5" />
        </div>
        <div>
          <h2 class="text-lg font-bold text-slate-100">推送规则配置</h2>
          <p class="text-xs text-slate-300">配置线索按等级自动推送至对应负责人</p>
        </div>
      </div>
      <button 
        @click="handleDispatch"
        v-if="currentRole === '超级管理员' || currentRole === '商务负责人'"
        class="bg-cyan-600 hover:bg-cyan-500 text-white text-xs font-bold px-4 py-2 rounded-xl flex items-center gap-1.5 transition shadow-lg shadow-cyan-600/20"
      >
        <Send class="h-3.5 w-3.5" />
        <span>手动推送</span>
      </button>
    </div>

    <!-- Rules Edit Area (inline) -->
    <div v-if="pushRules.length > 0" class="bg-slate-950 p-6 rounded-2xl border border-slate-800/80 space-y-4">
      <h3 class="text-sm font-bold text-slate-200 flex items-center gap-2">
        <Sliders class="h-4 w-4 text-cyan-400" />
        <span>推送规则</span>
      </h3>
      <div v-for="rule in pushRules" :key="rule.id" class="bg-slate-900/50 p-4 rounded-xl border border-slate-800/40 space-y-3">
        <div class="flex items-center justify-between">
          <span class="text-sm font-bold text-slate-200">{{ rule.ruleName }}</span>
          <span :class="['text-[10px] px-2 py-0.5 rounded', rule.status === 'active' ? 'bg-emerald-500/15 text-emerald-400' : 'bg-slate-800 text-slate-400']">
            {{ rule.status === 'active' ? '已生效' : '未启用' }}
          </span>
        </div>
        <div class="grid grid-cols-3 gap-3 text-xs">
          <div class="bg-slate-950 p-2.5 rounded-lg border border-slate-800/40">
            <span class="text-slate-400 block text-[10px]">高意向</span>
            <span class="font-bold text-emerald-400">{{ rule.highIntentMode === 'realtime' ? '实时推送' : '汇总' }}</span>
          </div>
          <div class="bg-slate-950 p-2.5 rounded-lg border border-slate-800/40">
            <span class="text-slate-400 block text-[10px]">中意向</span>
            <span class="font-bold text-amber-400">每日{{ rule.mediumIntentScheduleHour }}:{{ String(rule.mediumIntentScheduleMinute).padStart(2, '0') }}汇总</span>
          </div>
          <div class="bg-slate-950 p-2.5 rounded-lg border border-slate-800/40">
            <span class="text-slate-400 block text-[10px]">低意向</span>
            <span class="font-bold text-slate-300">{{ rule.lowIntentSilent ? '不主动推送' : '按需' }}</span>
          </div>
        </div>
        <div class="text-xs text-slate-300">
          <span class="text-slate-400">推送目标: </span>
          <span v-for="(t, i) in rule.targets" :key="i" class="mr-2">
            {{ t.receiverName }}({{ t.receiverRole }}) - {{ t.channels.join(', ') }}
          </span>
        </div>
      </div>
    </div>

    <!-- 推送记录历史 -->
    <div class="bg-slate-950 p-6 rounded-2xl border border-slate-800/80 space-y-4">
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-bold text-slate-200 flex items-center gap-2">
          <Activity class="h-4 w-4 text-cyan-400" />
          <span>推送记录</span>
        </h3>
        <button @click="fetchRecords" class="text-xs text-slate-400 hover:text-cyan-400 bg-slate-900 border border-slate-800 px-2.5 py-1 rounded-lg">刷新</button>
      </div>

      <div v-if="recordLoading" class="text-center py-8 text-slate-400 text-xs">
        <div class="inline-block animate-spin rounded-full h-4 w-4 border-b-2 border-cyan-400 mb-2"></div>
        <p>加载推送记录...</p>
      </div>

      <div v-else-if="pushRecords.length === 0" class="text-center py-8 text-slate-500 text-xs">
        <Send class="h-8 w-8 mx-auto mb-2 text-slate-700" />
        <p>暂无推送记录</p>
      </div>

      <div v-else class="space-y-2 max-h-[400px] overflow-y-auto">
        <div 
          v-for="rec in pushRecords" 
          :key="rec.id"
          class="bg-slate-900/50 p-3 rounded-xl border border-slate-800/40 text-xs"
        >
          <div class="flex items-center justify-between mb-1.5">
            <span class="font-bold text-slate-200">{{ rec.title }}</span>
            <span :class="['text-[10px] px-2 py-0.5 rounded-full font-bold', statusBadge(rec.status)]">{{ rec.status }}</span>
          </div>
          <div class="flex gap-2 text-[10px] text-slate-400">
            <span>接收: {{ rec.receiverName }}</span>
            <span>渠道: {{ (rec.channels||[]).join(', ') }}</span>
            <span>重试: {{ rec.retryCount }}/{{ rec.maxRetry }}</span>
          </div>
          <pre class="text-[10px] text-slate-300 mt-1 whitespace-pre-wrap font-sans">{{ rec.content?.slice(0, 120) }}...</pre>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { Sliders, Save, Send, Activity } from 'lucide-vue-next';
import { PushRule, PushRecord } from '../types';

const props = defineProps<{
  currentRole: string;
  operatorName: string;
}>();

const pushRules = ref<PushRule[]>([]);
const pushRecords = ref<PushRecord[]>([]);
const editingRule = ref<PushRule | null>(null);
const loading = ref(false);
const recordLoading = ref(false);

const fetchRules = async () => {
  loading.value = true;
  try {
    const res = await fetch('/api/push-rules');
    if (res.ok) pushRules.value = await res.json();
  } catch (err) {
    console.error(err);
  } finally {
    loading.value = false;
  }
};

const fetchRecords = async () => {
  recordLoading.value = true;
  try {
    const res = await fetch('/api/push-records');
    if (res.ok) pushRecords.value = await res.json();
  } catch (err) {
    console.error(err);
  } finally {
    recordLoading.value = false;
  }
};

const handleSaveRule = async () => {
  if (!editingRule.value) return;
  try {
    const res = await fetch('/api/push-rules', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(editingRule.value),
    });
    if (res.ok) {
      await fetchRules();
      alert('推送规则已更新');
    }
  } catch (err) {
    console.error(err);
  }
};

const handleDispatch = async () => {
  try {
    const res = await fetch('/api/push/dispatch', { method: 'POST' });
    if (res.ok) {
      const data = await res.json();
      alert(`推送完成: 高意向 ${data.highIntentCount} 条, 中意向 ${data.mediumIntentCount} 条`);
      await fetchRecords();
    } else {
      const err = await res.json();
      alert(err.error || '推送失败');
    }
  } catch (err) {
    console.error(err);
  }
};

const statusBadge = (status: PushRecord['status']) => {
  const m: Record<string, string> = {
    pending: 'bg-amber-500/15 text-amber-400',
    retrying: 'bg-orange-500/15 text-orange-400',
    sent: 'bg-emerald-500/15 text-emerald-400',
    failed: 'bg-rose-500/15 text-rose-400',
  };
  return m[status] || 'bg-slate-800 text-slate-300';
};

onMounted(() => {
  fetchRules();
  fetchRecords();
});
</script>