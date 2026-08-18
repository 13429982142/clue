<template>
  <div class="flex-1 p-6 flex overflow-hidden">
    <div class="flex-1 flex flex-col bg-slate-950/40 border border-slate-800 rounded-2xl overflow-hidden">
      
      <div class="p-4 bg-slate-950 border-b border-slate-800 flex flex-col md:flex-row md:items-center justify-between gap-4 shrink-0">
        <div class="flex items-center space-x-2">
          <FileText class="h-5 w-5 text-indigo-400" />
          <div>
            <h4 class="text-sm font-bold text-slate-200">AI 标书初稿与技术合作方案生成模块</h4>
            <p class="text-xs text-slate-300">选择标底大纲进行快速扩写，生成物料表格和项目敏捷部署周数规划。</p>
          </div>
        </div>

        <button 
          v-if="selectedLead"
          @click="emit('trigger-proposal', selectedLead.id)"
          :disabled="isDraftingProposal"
          class="bg-indigo-600 hover:bg-indigo-500 text-slate-100 text-xs font-bold px-3.5 py-2 rounded-xl flex items-center space-x-1.5 transition shrink-0 shadow-md shadow-indigo-600/10 disabled:opacity-50"
        >
          <Sparkles class="h-4 w-4 text-pink-400 animate-pulse" />
          <span>{{ isDraftingProposal ? '大模型正在扩写高阶物料清单...' : '一键扩写标书初稿' }}</span>
        </button>
      </div>

      <div class="flex-1 overflow-y-auto p-6 space-y-6">
        <div v-if="selectedLead" class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          <!-- 左侧：配置控制区 -->
          <div class="bg-slate-950 p-5 rounded-2xl border border-slate-800 space-y-4 h-fit">
            <span class="text-xs font-bold text-slate-300 block uppercase">方案定制控制台</span>
            
            <div>
              <label class="text-xs text-slate-400 block mb-1">1. 选择方案基底大纲 (PRD 模式库)</label>
              <select 
                :value="selectedTemplateId" 
                @change="emit('update-template', ($event.target as HTMLSelectElement).value)"
                class="bg-slate-900 border border-slate-800 text-slate-300 rounded-lg p-2 text-xs w-full focus:outline-none"
              >
                <option v-for="t in templates" :key="t.id" :value="t.id">{{ t.title }}</option>
              </select>
            </div>

            <div>
              <label class="text-xs text-slate-400 block mb-1">2. 测算估值与控制总计报价</label>
              <input 
                type="text" 
                :value="targetPrice" 
                @input="emit('update-price', ($event.target as HTMLInputElement).value)"
                placeholder="如：320w RMB"
                class="bg-slate-900 border border-slate-800 text-slate-300 rounded-lg p-2 text-xs w-full focus:outline-none"
              />
            </div>

            <div>
              <label class="text-xs text-slate-400 block mb-1">3. 用户指定额外增加或强化的高层技术设计规格 (FAQ-18 强关联)</label>
              <textarea 
                :value="customSpecs" 
                @input="emit('update-specs', ($event.target as HTMLTextAreaElement).value)"
                placeholder="如：增加现场防爆及多级冗余控制..."
                class="bg-slate-900 border border-slate-800 text-slate-300 rounded-lg p-2 text-xs w-full focus:outline-none h-[110px] resize-none"
              />
            </div>

            <div class="border-t border-slate-900 pt-3">
              <span class="text-xs text-slate-400 block font-bold uppercase mb-1">模板说明</span>
              <p class="text-xs text-slate-300 leading-relaxed">
                {{ templates.find(t => t.id === selectedTemplateId)?.description }}
              </p>
            </div>
          </div>

          <!-- 右侧：内容查看区 -->
          <div class="lg:col-span-2 space-y-4">
            <div class="bg-slate-900 p-4.5 rounded-xl border border-slate-800">
              <span class="text-xs font-bold text-slate-300 block uppercase mb-1">当前匹配跟进商机</span>
              <h3 class="text-sm font-bold text-slate-200">{{ selectedLead.title }}</h3>
              <p class="text-xs text-slate-300">{{ selectedLead.company }}</p>
            </div>

            <div v-if="selectedLead.proposalDraft" class="bg-slate-950 p-6 rounded-2xl border border-slate-850 text-xs text-slate-300 leading-relaxed whitespace-pre-wrap font-sans space-y-4">
              {{ selectedLead.proposalDraft }}
            </div>
            
            <div v-else class="p-12 text-center text-slate-400 border-2 border-dashed border-slate-800 bg-slate-950/20 rounded-xl">
              <BookOpen class="h-10 w-10 text-slate-700 mx-auto mb-2" />
              <span>暂未生成此线索对应项目方案书初稿。请配置左侧方案并点击右上角按钮。</span>
            </div>
          </div>

        </div>

        <div v-else class="text-center p-12 text-slate-400">
          请在全网监测列表选择任意线索，以开启针对该特定工程的技术方案合并撰写。
        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { defineProps, defineEmits } from 'vue';
import { FileText, Sparkles, BookOpen } from 'lucide-vue-next';
import { Lead, ProposalTemplate } from '../types';

const props = defineProps<{
  selectedLead: Lead | null;
  templates: ProposalTemplate[];
  isDraftingProposal: boolean;
  selectedTemplateId: string;
  targetPrice: string;
  customSpecs: string;
}>();

const emit = defineEmits<{
  (e: 'update-template', val: string): void;
  (e: 'update-price', val: string): void;
  (e: 'update-specs', val: string): void;
  (e: 'trigger-proposal', leadId: string): void;
}>();
</script>