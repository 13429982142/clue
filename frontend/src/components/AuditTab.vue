<template>
  <div class="flex-1 p-6 flex flex-col overflow-hidden max-w-5xl mx-auto w-full space-y-4">
    <div class="bg-slate-950 rounded-2xl border border-slate-800 flex-1 flex flex-col overflow-hidden shadow-2xl">

      <!-- 头部 -->
      <div class="p-4 bg-slate-950 border-b border-slate-800 shrink-0 flex flex-wrap items-center justify-between gap-3">
        <div class="flex items-center space-x-2">
          <ClipboardList class="h-5 w-5 text-emerald-400" />
          <div>
            <h4 class="text-sm font-bold text-slate-200">流转操作可信时间流与审计日志</h4>
            <p class="text-xs text-slate-400">系统记录每一个录入、更新、流转、作废与研判事件，保留备查且不可篡改。</p>
          </div>
        </div>

        <div class="flex items-center gap-2.5">
          <span class="text-xs bg-slate-900 border border-slate-800 px-3 py-1.5 rounded-xl text-slate-300 font-mono flex items-center gap-1.5 shadow-inner">
            <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            <span>累计事件：<b class="text-emerald-400 text-sm">{{ auditTotal ?? auditLogs.length }}</b> 条</span>
          </span>
          <button
            @click="emit('refresh')"
            class="bg-slate-900 hover:bg-slate-800 border border-slate-700 text-slate-300 hover:text-white px-3 py-1.5 rounded-xl text-xs flex items-center gap-1.5 transition cursor-pointer active:scale-95 shadow-sm"
            title="刷新最新审计日志"
          >
            <RefreshCw class="h-3.5 w-3.5" :class="isRefreshing ? 'animate-spin' : ''" />
            <span>刷新</span>
          </button>
        </div>
      </div>

      <!-- 快捷类型筛选栏 -->
      <div class="p-3 bg-slate-900/60 border-b border-slate-800/80 flex items-center gap-2 overflow-x-auto text-xs shrink-0">
        <button
          @click="selectedAction = ''"
          :class="[
            'px-2.5 py-1 rounded-lg transition font-medium cursor-pointer shrink-0',
            !selectedAction ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/40' : 'text-slate-400 hover:text-slate-200'
          ]"
        >
          全部 ({{ auditTotal ?? auditLogs.length }})
        </button>
        <button
          v-for="(count, action) in actionTypeCounts"
          :key="action"
          @click="selectedAction = String(action)"
          :class="[
            'px-2.5 py-1 rounded-lg transition font-medium cursor-pointer shrink-0 flex items-center gap-1',
            selectedAction === action ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/40' : 'text-slate-400 hover:text-slate-200'
          ]"
        >
          <span>{{ action }}</span>
          <span class="text-[10px] opacity-75 font-mono">({{ count }})</span>
        </button>
      </div>

      <!-- 日志列表 -->
      <div class="flex-1 overflow-y-auto p-4 space-y-3">
        <div v-for="log in filteredLogs" :key="log.id" class="bg-slate-900/40 border border-slate-800 p-3.5 rounded-xl text-xs space-y-1.5 hover:border-slate-700 transition">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-2.5">
              <span class="font-bold text-cyan-400 flex items-center gap-1">
                <span>👤</span>
                <span>{{ log.operator || '系统操作员' }}</span>
              </span>
              <span class="text-[10px] text-slate-400 bg-slate-950 border border-slate-800 px-1.5 py-0.5 rounded">
                {{ log.role || '商务专员' }}
              </span>
            </div>
            <span class="text-[10px] text-slate-500 font-mono">
              {{ (log.timestamp || '').replace('T', ' ').replace(/\+.*$/, '') }}
            </span>
          </div>

          <div class="flex items-center space-x-2 text-slate-300">
            <span class="text-xs bg-blue-600 border border-blue-500/40 text-white font-bold px-2 py-0.5 rounded-md">
              {{ log.actionType }}
            </span>
            <span v-if="log.targetTitle" class="text-slate-300 font-medium truncate max-w-[400px]">
              「{{ log.targetTitle }}」
            </span>
          </div>

          <p class="text-slate-400 leading-relaxed text-xs pt-1">
            {{ log.details }}
          </p>
        </div>

        <div v-if="filteredLogs.length === 0" class="py-16 text-center text-slate-500 text-xs">
          暂无审计日志记录
        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { ClipboardList, RefreshCw } from 'lucide-vue-next';
import { AuditLog } from '../types';

const props = defineProps<{
  auditLogs: AuditLog[];
  isRefreshing?: boolean;
  auditTotal?: number;
}>();

const emit = defineEmits<{
  (e: 'refresh'): void;
}>();

const selectedAction = ref('');

const actionTypeCounts = computed(() => {
  const map: Record<string, number> = {};
  (props.auditLogs || []).forEach((log) => {
    const act = log.actionType || '常规操作';
    map[act] = (map[act] || 0) + 1;
  });
  return map;
});

const filteredLogs = computed(() => {
  const list = props.auditLogs || [];
  if (!selectedAction.value) return list;
  return list.filter((l) => l.actionType === selectedAction.value);
});
</script>
