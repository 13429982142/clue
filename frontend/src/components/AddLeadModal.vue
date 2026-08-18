<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 backdrop-blur-sm p-4">
    <div class="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full p-6 space-y-4 shadow-2xl relative">
      <h3 class="text-lg font-bold text-slate-200 flex items-center space-x-2">
        <Plus class="h-5 w-5 text-cyan-400" />
        <span>手动录入大区商务政企线索</span>
      </h3>

      <form @submit.prevent="handleSubmit" class="space-y-4">
        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-xs text-slate-300 block">1. 商务项目标题名称 <span style="color:#ef4444">*</span></label>
            <input 
              type="text" 
              required
              v-model="localLeadData.title"
              class="bg-slate-950 border border-slate-800/80 text-slate-200 p-2 text-xs rounded-xl w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
            />
          </div>
          <div class="space-y-1">
            <label class="text-xs text-slate-300 block">2. 业主/采购企业全名 <span style="color:#ef4444">*</span></label>
            <input 
              type="text" 
              required
              v-model="localLeadData.company"
              class="bg-slate-950 border border-slate-800/80 text-slate-200 p-2 text-xs rounded-xl w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
            />
          </div>
        </div>

        <div class="grid grid-cols-3 gap-3">
          <div class="space-y-1">
            <label class="text-xs text-slate-300 block">3. 行政区域归属 <span style="color:#ef4444">*</span></label>
            <input 
              type="text" 
              required
              list="standard-provinces-list"
              v-model="localLeadData.region"
              @input="onRegionChange"
              placeholder="如：浙江省杭州市、湖北省孝感市"
              class="bg-slate-950 border border-slate-800/80 text-slate-200 p-2 text-xs rounded-xl w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
            />
            <datalist id="standard-provinces-list">
              <option v-for="prov in PROVINCES_STANDARD" :key="prov" :value="prov">{{ prov }}</option>
            </datalist>
            <p v-if="regionHint" class="text-[10px] text-cyan-400 mt-0.5">{{ regionHint }}</p>
          </div>
          <div class="space-y-1">
            <label class="text-xs text-slate-300 block">4. 细分行业归属</label>
            <select 
              v-model="localLeadData.industry"
              class="bg-slate-950 border border-slate-800/80 text-slate-200 p-2 text-xs rounded-xl w-full focus:outline-none"
            >
              <option value="污水自控">污水自控</option>
              <option value="智慧工厂">智慧工厂</option>
              <option value="智慧楼宇">智慧楼宇</option>
              <option value="高危污染监控">高危污染监控</option>
            </select>
          </div>
          <div class="space-y-1">
            <label class="text-xs text-slate-300 block">5. 物料分级归类</label>
            <select 
              v-model="localLeadData.category"
              class="bg-slate-950 border border-slate-800/80 text-slate-200 p-2 text-xs rounded-xl w-full focus:outline-none"
            >
              <option value="机电/节能改造">机电/节能改造</option>
              <option value="环保在线监视">环保在线监视</option>
            </select>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-xs text-slate-300 block">6. 预算金额（万元）</label>
            <input 
              type="number" 
              min="0"
              step="0.01"
              v-model.number="localLeadData.budgetAmount"
              placeholder="如：300"
              class="bg-slate-950 border border-slate-800/80 text-slate-200 p-2 text-xs rounded-xl w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
            />
          </div>
          <div class="space-y-1">
            <label class="text-xs text-slate-300 block">7. 项目阶段</label>
            <select 
              v-model="localLeadData.stageText"
              class="bg-slate-950 border border-slate-800/80 text-slate-200 p-2 text-xs rounded-xl w-full focus:outline-none"
            >
              <option value="">请选择项目阶段</option>
              <option value="需求调研">需求调研</option>
              <option value="方案设计">方案设计</option>
              <option value="招标采购">招标采购</option>
              <option value="施工建设">施工建设</option>
              <option value="竣工验收">竣工验收</option>
              <option value="运营维护">运营维护</option>
            </select>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-xs text-slate-300 block">8. 招标企业指定联系人</label>
            <input 
              type="text" 
              placeholder="如：刘主管"
              v-model="localLeadData.contactName"
              class="bg-slate-950 border border-slate-800/80 text-slate-200 p-2 text-xs rounded-xl w-full focus:outline-none"
            />
          </div>
          <div class="space-y-1">
            <label class="text-xs text-slate-300 block">9. 真实联系渠道电话</label>
            <input 
              type="text" 
              placeholder="如：138XXXX5678 或 0713-1234567"
              v-model="localLeadData.contactPhone"
              @blur="validatePhoneField"
              class="bg-slate-950 border border-slate-800/80 text-slate-200 p-2 text-xs rounded-xl w-full focus:outline-none"
            />
            <p v-if="phoneError" class="text-[11px] text-rose-400 mt-1">{{ phoneError }}</p>
          </div>
        </div>

        <div class="space-y-1">
          <label class="text-xs text-slate-300 block">10. 采购诉求与痛点描述说明 <span style="color:#ef4444">*</span></label>
          <textarea 
            required
            placeholder="请输入公告细节。例如：招标机电水泵自动节能改造，预算300w左右，合同质保不短于2年，要求投标方能免停水无损加装PLC阈自适应中台..."
            v-model="localLeadData.requirements"
            class="bg-slate-950 border border-slate-800/80 text-slate-200 p-2.5 text-xs rounded-xl w-full h-[80px] focus:outline-none focus:ring-1 focus:ring-cyan-500 resize-none"
          />
        </div>

        <!-- 手动评分初始化滑块面板 -->
        <div class="bg-slate-950 p-3 rounded-xl border border-slate-850 space-y-2">
          <span class="text-xs text-slate-400 font-bold block uppercase">设置初级评估因子 (0-100分，各占相应比例)</span>
          
          <div class="grid grid-cols-5 gap-3 text-center">
            <div>
              <span class="text-xs text-slate-300 block">项目规模分</span>
              <input 
                type="number" 
                min="10" 
                max="100" 
                v-model.number="localLeadData.budgetScore"
                class="bg-slate-900 border border-slate-800 rounded text-xs text-center p-1 w-full text-cyan-400 font-bold focus:outline-none"
              />
            </div>
            <div>
              <span class="text-xs text-slate-300 block">需求迫切度</span>
              <input 
                type="number" 
                min="10" 
                max="100" 
                v-model.number="localLeadData.matchScore"
                class="bg-slate-900 border border-slate-800 rounded text-xs text-center p-1 w-full text-cyan-400 font-bold focus:outline-none"
              />
            </div>
            <div>
              <span class="text-xs text-slate-300 block">资质匹配度</span>
              <input 
                type="number" 
                min="10" 
                max="100" 
                v-model.number="localLeadData.qualificationScore"
                class="bg-slate-900 border border-slate-800 rounded text-xs text-center p-1 w-full text-cyan-400 font-bold focus:outline-none"
              />
            </div>
            <div>
              <span class="text-xs text-slate-300 block">竞品偏好度</span>
              <input 
                type="number" 
                min="10" 
                max="100" 
                v-model.number="localLeadData.stageScore"
                class="bg-slate-900 border border-slate-800 rounded text-xs text-center p-1 w-full text-cyan-400 font-bold focus:outline-none"
              />
            </div>
            <div>
              <span class="text-xs text-slate-300 block">区域便利度</span>
              <input 
                type="number" 
                min="10" 
                max="100" 
                v-model.number="localLeadData.regionScore"
                class="bg-slate-900 border border-slate-850 rounded text-xs text-center p-1 w-full text-cyan-400 font-bold focus:outline-none"
              />
            </div>
          </div>
        </div>

        <div class="pt-3 flex items-center justify-end space-x-2.5">
          <button 
            type="button"
            @click="emit('close')"
            class="bg-gray-200 hover:bg-gray-300 border border-gray-400 text-xs px-4 py-2 rounded-xl transition"
            style="color:#000000!important"
          >
            取消
          </button>
          <button 
            type="submit"
            class="bg-gray-200 hover:bg-gray-300 border border-gray-400 text-xs font-bold px-5 py-2 rounded-xl transition shadow-md shadow-cyan-500/10"
            style="color:#000000!important"
          >
            确认加入并评估
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, defineEmits } from 'vue';
import { Plus } from 'lucide-vue-next';
import { PROVINCES_STANDARD, extractProvince, isValidLocation, cleanLocation } from '../services/provinceUtil';

const emit = defineEmits<{
  (e: 'close'): void;
  (e: 'submit', payload: any): void;
}>();

const regionHint = ref('');

const localLeadData = ref({
  title: '',
  company: '',
  region: '',
  industry: '污水自控',
  category: '机电/节能改造',
  sourceDb: '手动加入',
  requirements: '',
  notes: '',
  budgetScore: 60,
  matchScore: 60,
  qualificationScore: 60,
  stageScore: 40,
  regionScore: 50,
  contactName: '',
  contactPhone: '',
  budgetAmount: undefined,
  stageText: '招标采购',
});

const onRegionChange = () => {
  const inputVal = localLeadData.value.region.trim();
  if (!inputVal) {
    regionHint.value = '';
    localLeadData.value.regionScore = 50;
    return;
  }
  const prov = extractProvince(inputVal);
  if (prov) {
    regionHint.value = `✓ 已识别为归属省份：${prov}`;
    // 华东/华南等重点监控区域给高分，其他省份给标准分
    if (['浙江省', '湖北省', '广东省', '江苏省', '山东省', '四川省'].includes(prov)) {
      localLeadData.value.regionScore = 80;
    } else {
      localLeadData.value.regionScore = 65;
    }
  } else if (isValidLocation(inputVal)) {
    regionHint.value = '✓ 自定义地理区域';
    localLeadData.value.regionScore = 60;
  } else {
    regionHint.value = '⚠ 未识别到具体行政省份或地市';
    localLeadData.value.regionScore = 40;
  }
};

// 项目阶段文本 → 分值映射
const STAGE_MAP: Record<string, number> = {
  '需求调研': 20,
  '方案设计': 40,
  '招标采购': 60,
  '施工建设': 70,
  '竣工验收': 80,
  '运营维护': 50,
};

const handleSubmit = () => {
  // 项目阶段文本转分数
  if (localLeadData.value.stageText) {
    localLeadData.value.stageScore = STAGE_MAP[localLeadData.value.stageText] || 50;
  }
  // 规范化清洗地点
  const rawRegion = localLeadData.value.region.trim();
  const cleanedRegion = cleanLocation(rawRegion);
  localLeadData.value.region = cleanedRegion || rawRegion || '待核验地区';
  // 手机号 / 座机号校验（选填字段）
  phoneError.value = validatePhone(localLeadData.value.contactPhone);
  if (phoneError.value) return;
  emit('submit', localLeadData.value);
};

const phoneError = ref('');

const validatePhoneField = () => {
  phoneError.value = validatePhone(localLeadData.value.contactPhone);
};

// 支持手机号（1[3-9]开头11位）或座机号（区号3-4位 + 7-8位号码，可带分机）
const validatePhone = (p: string) => {
  if (!p || !p.trim()) return ''; // 选填，为空不校验
  const val = p.trim();
  const mobile = /^1[3-9]\d{9}$/;
  const landline = /^0\d{2,3}-?\d{7,8}(-\d{1,5})?$/;
  if (mobile.test(val) || landline.test(val)) return '';
  return '手机号需为 11 位（如 13800138000），座机号格式如 0713-1234567';
};
</script>