<template>
  <div class="min-h-screen bg-slate-50 flex items-center justify-center p-4 font-sans select-none antialiased relative overflow-hidden">

    <!-- 1. tsParticles 粒子背景（固定全屏，卡片 z-10 在其上层，不影响表单交互） -->
    <VueParticles
      id="tsparticles"
      class="fixed inset-0 w-full h-full z-0"
      :options="particlesOptions"
    />

    <!-- 柔和的底层霓虹光晕（在粒子下方提供环境色） -->
    <div class="absolute top-1/4 left-1/4 w-96 h-96 bg-cyan-400/20 rounded-full blur-3xl pointer-events-none z-0"></div>
    <div class="absolute bottom-1/4 right-1/4 w-96 h-96 bg-indigo-400/20 rounded-full blur-3xl pointer-events-none z-0"></div>

    <!-- 2. 主卡片 -->
    <div class="w-full max-w-md bg-white/80 border border-slate-200/80 rounded-[2rem] p-8 shadow-[0_20px_50px_rgba(15,23,42,0.06)] backdrop-blur-xl relative z-10 transition-all duration-300">

      <!-- 品牌标志头部 -->
      <div class="flex flex-col items-center mb-8">
        <div class="bg-gradient-to-tr from-cyan-500 to-indigo-600 p-3 rounded-2xl text-white shadow-lg shadow-indigo-500/20 mb-4 transition-transform hover:scale-105 duration-300">
          <Building2 class="h-8 w-8 stroke-[1.5]" />
        </div>
        <h1 class="text-2xl font-extrabold tracking-tight text-slate-900">
          污水智控·商机大脑
        </h1>
      </div>

      <!-- 标签切换器 -->
      <div class="flex bg-slate-100 p-1 rounded-xl border border-slate-200/60 mb-6">
        <button
            @click="isLogin = true; errorMsg = ''; successMsg = '';"
            :class="[
            'flex-1 text-center py-2 text-xs font-bold rounded-lg transition-all duration-200 focus:outline-none',
            isLogin ? 'bg-white text-slate-900 shadow-sm border border-slate-200/50' : 'text-slate-500 hover:text-slate-800'
          ]"
        >
          账号登录
        </button>
        <button
            @click="isLogin = false; errorMsg = ''; successMsg = '';"
            :class="[
            'flex-1 text-center py-2 text-xs font-bold rounded-lg transition-all duration-200 focus:outline-none',
            !isLogin ? 'bg-white text-slate-900 shadow-sm border border-slate-200/50' : 'text-slate-500 hover:text-slate-800'
          ]"
        >
          注册新用户
        </button>
      </div>

      <!-- 认证表单 -->
      <form @submit.prevent="handleSubmit" class="space-y-4">

        <!-- 用户名 -->
        <div>
          <label class="text-xs text-slate-500 font-bold block mb-1.5 uppercase tracking-wider">用户名</label>
          <div class="relative group">
            <User class="absolute left-3.5 top-3 h-4 w-4 text-slate-400 group-focus-within:text-cyan-500 transition-colors" />
            <input
                type="text"
                v-model="username"
                placeholder="请输入登录用户名"
                class="w-full bg-slate-50/60 border border-slate-200 rounded-xl py-3 pl-10 pr-4 text-xs text-slate-800 focus:outline-none focus:ring-4 focus:ring-cyan-500/10 focus:border-cyan-500 transition-all placeholder:text-slate-400"
                required
            />
          </div>
        </div>

        <!-- 密码 -->
        <div>
          <label class="text-xs text-slate-500 font-bold block mb-1.5 uppercase tracking-wider">密码</label>
          <div class="relative group">
            <Lock class="absolute left-3.5 top-3 h-4 w-4 text-slate-400 group-focus-within:text-cyan-500 transition-colors" />
            <input
                type="password"
                v-model="password"
                placeholder="请输入登录密码"
                class="w-full bg-slate-50/60 border border-slate-200 rounded-xl py-3 pl-10 pr-4 text-xs text-slate-800 focus:outline-none focus:ring-4 focus:ring-cyan-500/10 focus:border-cyan-500 transition-all placeholder:text-slate-400"
                required
            />
          </div>
        </div>

        <!-- 真实姓名（仅注册时显示） -->
        <div v-if="!isLogin" class="animate-fade-in">
          <label class="text-xs text-slate-500 font-bold block mb-1.5 uppercase tracking-wider">真实姓名</label>
          <div class="relative group">
            <Sparkles class="absolute left-3.5 top-3 h-4 w-4 text-slate-400 group-focus-within:text-cyan-500 transition-colors" />
            <input
                type="text"
                v-model="name"
                placeholder="如：商务专员王小二"
                class="w-full bg-slate-50/60 border border-slate-200 rounded-xl py-3 pl-10 pr-4 text-xs text-slate-800 focus:outline-none focus:ring-4 focus:ring-cyan-500/10 focus:border-cyan-500 transition-all placeholder:text-slate-400"
                required
            />
          </div>
        </div>

        <!-- 错误提示 -->
        <div v-if="errorMsg" class="bg-rose-50 border border-rose-200 text-rose-600 rounded-xl p-3 text-xs flex items-center space-x-2 animate-shake">
          <span class="w-1.5 h-1.5 bg-rose-500 rounded-full shrink-0 animate-ping"></span>
          <span>{{ errorMsg }}</span>
        </div>

        <!-- 成功提示 -->
        <div v-if="successMsg" class="bg-emerald-50 border border-emerald-200 text-emerald-600 rounded-xl p-3 text-xs flex items-center space-x-2">
          <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full shrink-0"></span>
          <span>{{ successMsg }}</span>
        </div>

        <!-- 提交按钮 -->
        <button
            type="submit"
            :disabled="isLoading"
            class="w-full bg-gradient-to-r from-cyan-500 to-indigo-600 hover:opacity-95 text-white font-bold text-xs py-3.5 rounded-xl transition-all duration-300 shadow-md shadow-indigo-500/10 focus:outline-none flex items-center justify-center space-x-2 disabled:opacity-50 hover:scale-[1.01] active:scale-[0.99] transform"
        >
          <span v-if="isLoading" class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          <span v-else class="tracking-wider">{{ isLogin ? '进入控制台' : '完成注册' }}</span>
        </button>

      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, defineEmits } from 'vue';
import { Building2, User, Lock, Sparkles } from 'lucide-vue-next';
import { User as UserType } from '../types';
import type { ISourceOptions } from '@tsparticles/engine';

const emit = defineEmits<{
  (e: 'login-success', user: UserType): void;
}>();

const isLogin = ref(true);
const username = ref('');
const password = ref('');
const name = ref('');

const errorMsg = ref('');
const successMsg = ref('');
const isLoading = ref(false);

// ---- tsParticles 粒子背景配置（插件在 main.ts 全局注册） ----
const particlesOptions: ISourceOptions = {
  fullScreen: { enable: false },
  background: { color: 'transparent' },
  fpsLimit: 60,
  interactivity: {
    events: {
      onHover: { enable: true, mode: 'grab' },
      resize: true,
    },
    modes: {
      grab: { distance: 170, links: { opacity: 0.5 } },
    },
  },
  particles: {
    number: {
      value: 300,
      density: { enable: true },
    },
    color: { value: '#334155' }, // 兼容 v3 配置，部分版本仍读取
    paint: {
      color: { value: '#334155' }, // slate-700 深灰，白底清晰且低调
      fill: { enable: true, opacity: 1 },
    },
    shape: { type: 'circle' },
    opacity: { value: 1 },
    size: { value: { min: 1, max: 2.5 } },
    links: {
      enable: true,
      distance: 130,
      color: '#475569', // slate-600 深灰连线，白底清晰
      opacity: 0.45,
      width: 1,
    },
    move: {
      enable: true,
      speed: 1.2,
      direction: 'none',
      random: false,
      straight: false,
      outModes: { default: 'bounce' },
    },
  },
  detectRetina: true,
};

const handleSubmit = async () => {
  errorMsg.value = '';
  successMsg.value = '';

  if (!username.value || !password.value) {
    errorMsg.value = '用户名和密码不能为空';
    return;
  }

  if (!isLogin.value && !name.value) {
    errorMsg.value = '真实姓名不能为空';
    return;
  }

  isLoading.value = true;
  try {
    const url = isLogin.value ? '/api/auth/login' : '/api/auth/register';
    const body = isLogin.value
        ? { username: username.value, password: password.value }
        : { username: username.value, password: password.value, name: name.value, role: '商务专员' };

    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });

    const data = await res.json();
    if (!res.ok) {
      errorMsg.value = data.detail || data.error || '操作失败，请重试';
    } else {
      if (isLogin.value) {
        successMsg.value = '登录成功！正在跳转...';
        setTimeout(() => {
          emit('login-success', data);
        }, 800);
      } else {
        successMsg.value = '注册成功！请登录。';
        isLogin.value = true;
        name.value = '';
      }
    }
  } catch (err) {
    console.error(err);
    errorMsg.value = '网络连接异常，请检查网络后重试';
  } finally {
    isLoading.value = false;
  }
};
</script>

<style scoped>
/* 注册栏展开动效 */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(4px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fade-in {
  animation: fadeIn 0.3s ease-out forwards;
}

/* 错误提示框抖动动效 */
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-3px); }
  75% { transform: translateX(3px); }
}
.animate-shake {
  animation: shake 0.25s ease-in-out 2;
}
</style>