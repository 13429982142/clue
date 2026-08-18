<template>
  <div class="flex-1 p-8 overflow-y-auto max-w-5xl mx-auto w-full space-y-6">
    <!-- 头部 -->
    <div class="soft-panel-strong bg-gradient-to-r from-slate-900 via-slate-950 to-slate-900 border border-slate-800 p-6 rounded-2xl flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div class="bg-indigo-500/10 p-2 rounded-xl text-indigo-400 border border-indigo-500/20">
          <Building2 class="h-5 w-5" />
        </div>
        <div>
          <h2 class="text-lg font-bold text-slate-100">客户档案与项目台账</h2>
          <p class="text-xs text-slate-300">已转化线索自动生成的客户档案和项目台账(4.2.4)</p>
        </div>
      </div>
    </div>

    <div v-if="loading" class="text-center py-12 text-slate-400 text-sm">
      <div class="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-cyan-400 mb-3"></div>
      <p>加载中...</p>
    </div>

    <div v-else-if="customers.length === 0" class="text-center py-16 text-slate-500">
      <Building2 class="h-12 w-12 mx-auto mb-3 text-slate-700" />
      <p class="text-sm">暂无已转化客户</p>
      <p class="text-xs text-slate-500 mt-1">将线索状态推进至「跟进中」→「已转化」后,自动生成客户档案和项目台账</p>
    </div>

    <template v-else>
      <!-- Customers -->
      <div class="bg-slate-950 p-6 rounded-2xl border border-slate-800/80 space-y-4">
        <h3 class="text-sm font-bold text-slate-200 flex items-center gap-2">
          <Users class="h-4 w-4 text-cyan-400" />
          <span>客户档案 ({{ customers.length }})</span>
        </h3>
        <div class="grid gap-3">
          <div v-for="c in customers" :key="c.id" class="bg-slate-900/50 p-4 rounded-xl border border-slate-800/40 space-y-2">
            <div class="flex items-center justify-between">
              <span class="text-sm font-bold text-slate-200">{{ c.company }}</span>
              <span class="text-[10px] text-slate-400 font-mono">{{ (c.convertedAt || '').replace('T', ' ').replace(/\+.*$/, '') }}</span>
            </div>
            <div class="grid grid-cols-2 gap-2 text-xs">
              <div><span class="text-slate-400">联系人:</span> <span class="text-slate-300">{{ c.contactName || '待补充' }}</span></div>
              <div><span class="text-slate-400">联系方式:</span> <span class="text-slate-300">{{ c.contactPhone || '待补充' }}</span></div>
              <div><span class="text-slate-400">地区:</span> <span class="text-slate-300">{{ c.region || '待补充' }}</span></div>
              <div><span class="text-slate-400">转化人:</span> <span class="text-slate-300">{{ c.convertedBy }}</span></div>
            </div>
            <div v-if="c.sourceDb" class="pt-1">
              <a :href="c.sourceDb" target="_blank" class="text-[10px] text-cyan-400 hover:text-cyan-300 underline underline-offset-2 break-all">原文链接</a>
            </div>
          </div>
        </div>
      </div>

      <!-- 项目台账 -->
      <div class="bg-slate-950 p-6 rounded-2xl border border-slate-800/80 space-y-4">
        <h3 class="text-sm font-bold text-slate-200 flex items-center gap-2">
          <FolderKanban class="h-4 w-4 text-indigo-400" />
          <span>项目台账 ({{ projects.length }})</span>
        </h3>
        <div class="grid gap-3">
          <div v-for="p in projects" :key="p.id" class="bg-slate-900/50 p-4 rounded-xl border border-slate-800/40 space-y-2">
            <div class="flex items-center justify-between">
              <span class="text-sm font-bold text-slate-200">{{ p.projectName }}</span>
            </div>
            <div class="flex gap-3 text-xs text-slate-300">
              <span>预算: {{ p.budgetAmount ?? '待补充' }}万元</span>
              <span>创建: {{ (p.createdAt || '').replace('T', ' ').replace(/\+.*$/, '') }}</span>
              <span>负责人: {{ p.createdBy }}</span>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { Building2, FolderKanban, Users } from 'lucide-vue-next';
import { CustomerProfile, ProjectLedger, LeadActivity } from '../types';

const props = defineProps<{
  currentRole: string;
  operatorName: string;
}>();

const customers = ref<CustomerProfile[]>([]);
const projects = ref<ProjectLedger[]>([]);
const loading = ref(false);

const fetchData = async () => {
  loading.value = true;
  try {
    const [cRes, pRes] = await Promise.all([
      fetch('/api/customers'),
      fetch('/api/projects'),
    ]);
    if (cRes.ok) customers.value = await cRes.json();
    if (pRes.ok) projects.value = await pRes.json();
  } catch (err) {
    console.error(err);
  } finally {
    loading.value = false;
  }
};

onMounted(fetchData);
</script>