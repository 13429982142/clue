import { createApp } from 'vue';
import App from './App.vue';
import './index.css';
import VueParticles from '@tsparticles/vue3';
import { loadSlim } from '@tsparticles/slim';
import type { Engine } from '@tsparticles/engine';

// 全局注册 tsParticles 插件（组件名为 VueParticles）
createApp(App)
  .use(VueParticles, {
    init: async (engine: Engine) => {
      await loadSlim(engine);
    },
  })
  .mount('#root');
