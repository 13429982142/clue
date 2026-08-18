<template>
  <div class="flex-1 p-6 flex overflow-hidden">
    <div class="flex-1 flex flex-col bg-slate-950/40 border border-slate-800 rounded-2xl overflow-hidden">
      
      <!-- 头部 -->
      <div class="p-4 bg-slate-950 border-b border-slate-800 flex flex-col md:flex-row md:items-center justify-between gap-4 shrink-0">
        <div class="flex items-center space-x-2">
          <Users class="h-5 w-5 text-cyan-400" />
          <div>
            <h4 class="text-sm font-bold text-slate-200">系统用户与权限管理</h4>
            <p class="text-xs text-slate-300">管理系统账号、分配角色权限，实现精细化数据隔离与安全审计。</p>
          </div>
        </div>

        <button 
          @click="showAddUserForm = !showAddUserForm"
          class="bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white text-xs font-bold px-3.5 py-2 rounded-xl flex items-center space-x-1.5 transition shrink-0 shadow-md shadow-blue-900/30"
        >
          <Plus class="h-4 w-4" />
          <span>新增系统用户</span>
        </button>
      </div>

      <!-- 主要内容区域 -->
      <div class="flex-1 overflow-y-auto p-6 space-y-6">
        
        <!-- 提示信息 -->
        <div v-if="errorMsg" class="bg-rose-950/30 border border-rose-800/50 text-rose-400 rounded-xl p-3 text-xs flex items-center space-x-2">
          <span class="w-1.5 h-1.5 bg-rose-500 rounded-full shrink-0 animate-ping"></span>
          <span class="flex-1">{{ errorMsg }}</span>
          <button @click="errorMsg = ''" class="shrink-0 text-rose-300 hover:text-rose-100 transition">&times;</button>
        </div>
        <div v-if="successMsg" class="bg-emerald-950/30 border border-emerald-800/50 text-emerald-400 rounded-xl p-3 text-xs flex items-center space-x-2">
          <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full shrink-0"></span>
          <span>{{ successMsg }}</span>
        </div>

        <!-- 添加用户表单面板 -->
        <div v-if="showAddUserForm" class="bg-slate-950 p-5 rounded-2xl border border-slate-800 space-y-4">
          <span class="text-xs font-bold text-slate-300 block uppercase">创建新账号</span>
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div>
              <label class="text-xs text-slate-400 block mb-1">用户名<span class="text-rose-400">*</span></label>
              <input 
                type="text" 
                v-model="username" 
                placeholder="如：sales_wang"
                class="bg-slate-900 border border-slate-800 text-slate-300 rounded-lg p-2 text-xs w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
              />
            </div>

            <div>
              <label class="text-xs text-slate-400 block mb-1">登录密码 <span class="text-rose-400">*</span></label>
              <input 
                type="password" 
                v-model="password" 
                placeholder="密码不少于6位"
                class="bg-slate-900 border border-slate-800 text-slate-300 rounded-lg p-2 text-xs w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
              />
            </div>

            <div>
              <label class="text-xs text-slate-400 block mb-1">真实姓名<span class="text-rose-400">*</span></label>
              <input 
                type="text" 
                v-model="name" 
                placeholder="如：王五"
                class="bg-slate-900 border border-slate-800 text-slate-300 rounded-lg p-2 text-xs w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
              />
            </div>

            <div>
              <label class="text-xs text-slate-400 block mb-1">角色权限级别 <span class="text-rose-400">*</span></label>
              <select 
                v-model="role"
                class="bg-slate-900 border border-slate-800 text-slate-300 rounded-lg p-2 text-xs w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
              >
                <option value="商务负责人">商务负责人</option>
                <option value="商务专员">商务专员</option>
              </select>
            </div>
          </div>

          <div class="flex justify-end space-x-3 pt-2">
            <button 
              @click="closeAddForm"
              class="px-4 py-2 bg-slate-900 hover:bg-slate-850 text-slate-300 text-xs font-bold rounded-xl transition"
            >
              取消
            </button>
            <button 
              @click="handleAddUser"
              class="px-4 py-2 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white text-xs font-bold rounded-xl transition shadow-md shadow-blue-900/30"
            >
              确认创建
            </button>
          </div>
        </div>

        <!-- 用户列表表格 -->
        <div class="bg-slate-950 rounded-2xl border border-slate-800 overflow-hidden">
          <div class="p-4 border-b border-slate-800 bg-slate-950/50 flex justify-between items-center">
            <span class="text-xs font-bold text-slate-300 uppercase tracking-wider">系统用户列表 ({{ users.length }})</span>
            <span class="text-[10px] text-slate-400 font-mono">数据隔离状态: 已激活</span>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="border-b border-slate-800 text-[10px] text-slate-400 uppercase font-bold tracking-wider bg-slate-950/20">
                  <th class="p-4">真实姓名</th>
                  <th class="p-4">用户名</th>
                  <th class="p-4">角色权限</th>
                  <th class="p-4">创建时间</th>
                  <th class="p-4 text-right">操作</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-800/50 text-xs text-slate-300">
                <tr v-for="user in users" :key="user.id" class="hover:bg-slate-900/30 transition-all">
                  <td class="p-4 font-semibold text-slate-200">
                    <div class="flex items-center space-x-2">
                      <div class="w-8 h-8 rounded-full bg-slate-900 border border-slate-800 flex items-center justify-center text-xs font-bold text-cyan-400">
                        {{ user.name.charAt(0) }}
                      </div>
                      <div>
                        <span class="block text-slate-200 font-bold">{{ user.name }}</span>
                        <span v-if="user.id === currentUser.id" class="text-[9px] bg-cyan-500/10 text-cyan-400 px-1.5 py-0.5 rounded-md font-bold font-mono">当前账号</span>
                      </div>
                    </div>
                  </td>
                  <td class="p-4 font-mono text-slate-300">{{ user.username }}</td>
                  <td class="p-4">
                    <div class="flex items-center space-x-2">
                      <Shield class="h-3.5 w-3.5 text-cyan-500" />
                      <template v-if="user.role === '超级管理员'">
                        <span class="bg-amber-500/10 text-amber-400 border border-amber-600/30 rounded-lg py-1 px-2 text-xs font-bold">{{ user.role }}</span>
                      </template>
                      <select 
                        v-else
                        :value="user.role"
                        @change="handleUpdateRole(user.id, ($event.target as HTMLSelectElement).value as User['role'])"
                        :disabled="user.id === currentUser.id"
                        class="bg-slate-900 border border-slate-800 text-slate-300 rounded-lg py-1 px-2 text-xs focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <option value="商务负责人">商务负责人</option>
                        <option value="商务专员">商务专员</option>
                      </select>
                    </div>
                  </td>
                  <td class="p-4 text-slate-400 font-mono text-xs">
                    <div class="flex items-center space-x-1.5">
                      <Clock class="h-3.5 w-3.5 text-slate-500" />
                      <span>{{ (user.createdAt || '').replace('T', ' ').replace(/\+.*$/, '') }}</span>
                    </div>
                  </td>
                  <td class="p-4 text-right">
                    <div class="flex items-center justify-end space-x-2">
                      <button 
                        @click="openEdit(user)"
                        :disabled="user.id === 'user-admin' && currentUser.id !== 'user-admin'"
                        class="p-1.5 bg-slate-900 hover:bg-cyan-950/30 border border-slate-800 hover:border-cyan-800/40 text-slate-400 hover:text-cyan-400 rounded-lg transition disabled:opacity-30 disabled:hover:bg-slate-900 disabled:hover:border-slate-800 disabled:hover:text-slate-400 disabled:cursor-not-allowed"
                        title="修改用户"
                      >
                        <Pencil class="h-4 w-4" />
                      </button>
                      <button 
                        @click="handleDeleteUser(user)"
                        :disabled="user.id === 'user-admin' || user.id === currentUser.id"
                        class="p-1.5 bg-slate-900 hover:bg-rose-950/30 border border-slate-800 hover:border-rose-800/40 text-slate-400 hover:text-rose-400 rounded-lg transition disabled:opacity-30 disabled:hover:bg-slate-900 disabled:hover:border-slate-800 disabled:hover:text-slate-400 disabled:cursor-not-allowed"
                        title="删除用户"
                      >
                        <Trash2 class="h-4 w-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- 编辑用户弹窗 -->
        <div v-if="editUser" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div class="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl">
            <h3 class="text-sm font-bold text-slate-200">修改用户信息</h3>
            <p class="text-xs text-slate-400">正在修改 <span class="text-cyan-400 font-bold">{{ editUser.name }}</span></p>

            <!-- 失败/成功提醒 -->
            <div v-if="errorMsg" class="bg-rose-950/30 border border-rose-800/50 text-rose-400 rounded-xl p-3 text-xs flex items-center space-x-2">
              <span class="w-1.5 h-1.5 bg-rose-500 rounded-full shrink-0 animate-ping"></span>
              <span>{{ errorMsg }}</span>
            </div>
            <div v-if="successMsg" class="bg-emerald-950/30 border border-emerald-800/50 text-emerald-400 rounded-xl p-3 text-xs flex items-center space-x-2">
              <span class="w-1.5 h-1.5 bg-emerald-500 rounded-full shrink-0"></span>
              <span>{{ successMsg }}</span>
            </div>

            <div class="space-y-3">
              <div>
                <label class="text-xs text-slate-400 block mb-1">用户名</label>
                <input 
                  type="text" 
                  v-model="editUsername" 
                  class="bg-slate-950 border border-slate-800 text-slate-200 rounded-lg p-2 text-xs w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
                />
              </div>
              <div>
                <label class="text-xs text-slate-400 block mb-1">真实姓名</label>
                <input 
                  type="text" 
                  v-model="editName" 
                  class="bg-slate-950 border border-slate-800 text-slate-200 rounded-lg p-2 text-xs w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
                />
              </div>
              <div>
                <label class="text-xs text-slate-400 block mb-1">新密码（留空不修改）</label>
                <input 
                  type="password" 
                  v-model="editPassword" 
                  placeholder="输入新密码"
                  class="bg-slate-950 border border-slate-800 text-slate-200 rounded-lg p-2 text-xs w-full focus:outline-none focus:ring-1 focus:ring-cyan-500"
                />
              </div>
            </div>

            <div class="flex justify-end space-x-3 pt-2">
              <button 
                @click="editUser = null"
                class="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold rounded-xl transition"
              >
                取消
              </button>
              <button 
                @click="handleEditSubmit"
                class="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold rounded-xl transition"
              >
                确认修改
              </button>
            </div>
          </div>
        </div>

        <!-- 数据隔离策略卡片 -->
        <div class="bg-slate-950 p-5 rounded-2xl border border-slate-800 flex items-start space-x-4">
          <ShieldAlert class="h-6 w-6 text-cyan-500 shrink-0 mt-0.5" />
          <div class="space-y-1">
            <h5 class="text-xs font-bold text-slate-200">系统数据隔离与安全审计策略</h5>
            <p class="text-xs text-slate-300 leading-relaxed">
              1. **超级管理员 / 商务负责人**：拥有全量商务线索、网监配置、竞品库及审计日志的读写与配置权限。<br />
              2. **商务专员**：实施精细化数据隔离，**仅能查看并跟进自己负责（被分配）或自己创建的商务线索**，审计日志仅显示个人操作轨迹。<br />
              3. **安全审计**：所有用户的登录、录入、修改、删除等操作均会被实时载入审计日志，无法篡改。
            </p>
          </div>
        </div>

      </div>

    </div>

    <!-- 居中二次确认弹窗 -->
    <div v-if="confirmTarget" class="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 backdrop-blur-sm p-4" @click.self="closeConfirm">
      <div class="bg-slate-900 border border-slate-700 rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden">
        <div class="px-5 py-4 border-b border-slate-800 flex items-center justify-between">
          <h4 class="text-sm font-bold text-slate-200">删除用户确认</h4>
          <button @click="closeConfirm" class="text-slate-400 hover:text-slate-200 text-lg leading-none">&times;</button>
        </div>
        <div class="px-5 py-5 text-sm text-slate-300 leading-relaxed">
          您确定要彻底删除用户 「<span class="text-rose-400 font-bold">{{ confirmTarget.name }}</span>」 吗？该操作不可恢复。
        </div>
        <div class="px-5 pb-5 flex justify-end gap-2">
          <button @click="closeConfirm" class="px-4 py-2 text-xs text-slate-300 border border-slate-600 rounded-lg transition cursor-pointer">取消</button>
          <button @click="confirmDeleteUser" class="px-4 py-2 text-xs text-white font-semibold bg-rose-600 hover:bg-rose-500 rounded-lg transition cursor-pointer">确定删除</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, defineProps } from 'vue';
import { ShieldAlert, UserCheck, Trash2, Plus, Users, Shield, Clock, Key, Pencil } from 'lucide-vue-next';
import { User } from '../types';

const props = defineProps<{
  currentUser: User;
}>();

const users = ref<User[]>([]);
const isLoading = ref(false);
const errorMsg = ref('');
const successMsg = ref('');

// 添加用户表单状态
const showAddUserForm = ref(false);
const username = ref('');
const password = ref('');
const name = ref('');
const role = ref<'商务负责人' | '商务专员'>('商务专员');

// 编辑用户状态
const editUser = ref<User | null>(null);
const editName = ref('');
const editUsername = ref('');
const editPassword = ref('');

const fetchUsers = async () => {
  isLoading.value = true;
  errorMsg.value = '';
  try {
    const res = await fetch('/api/users');
    if (res.ok) {
      users.value = await res.json();
    } else {
      const data = await res.json();
      errorMsg.value = data.error || '获取用户列表失败';
    }
  } catch (err) {
    console.error(err);
    errorMsg.value = '请求失败，请检查网络';
  } finally {
    isLoading.value = false;
  }
};

// 关闭新增表单（清空校验提醒并重置表单）
const closeAddForm = () => {
  showAddUserForm.value = false;
  errorMsg.value = '';
  username.value = '';
  password.value = '';
  name.value = '';
  role.value = '商务专员';
};

const handleAddUser = async () => {
  errorMsg.value = '';
  successMsg.value = '';
  if (!username.value || !password.value || !name.value || !role.value) {
    errorMsg.value = '所有字段均为必填项';
    return;
  }

  try {
    const res = await fetch('/api/users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        username: username.value,
        password: password.value,
        name: name.value,
        role: role.value
      })
    });

    const data = await res.json();
    if (res.ok) {
      successMsg.value = `成功创建用户 「${data.name}」`;
      showAddUserForm.value = false;
      // 重置表单
      username.value = '';
      password.value = '';
      name.value = '';
      role.value = '商务专员';
      // 刷新列表
      fetchUsers();
    } else {
      errorMsg.value = data.error || '创建用户失败';
    }
  } catch (err) {
    console.error(err);
    errorMsg.value = '请求失败，请检查网络';
  }
};

const handleUpdateRole = async (userId: string, newRole: User['role']) => {
  errorMsg.value = '';
  successMsg.value = '';
  try {
    const res = await fetch(`/api/users/${userId}/role`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ role: newRole })
    });

    const data = await res.json();
    if (res.ok) {
      successMsg.value = `用户 「${data.name}」 角色已更新为 「${data.role}」`;
      fetchUsers();
    } else {
      errorMsg.value = data.error || '更新角色失败';
    }
  } catch (err) {
    console.error(err);
    errorMsg.value = '请求失败，请检查网络';
  }
};

const handleDeleteUser = async (user: User) => {
  if (user.id === 'user-admin' || user.username === 'admin') {
    alert('不能删除初始超级管理员账号！');
    return;
  }
  confirmTarget.value = user;
};

const confirmTarget = ref<User | null>(null);

// 关闭确认弹窗（同时清空校验提醒）
const closeConfirm = () => {
  confirmTarget.value = null;
  errorMsg.value = '';
};

const confirmDeleteUser = async () => {
  if (!confirmTarget.value) return;
  const user = confirmTarget.value;
  confirmTarget.value = null;
  errorMsg.value = '';
  successMsg.value = '';
  try {
    const res = await fetch(`/api/users/${user.id}`, {
      method: 'DELETE'
    });

    if (res.ok) {
      successMsg.value = `成功删除用户 「${user.name}」`;
      fetchUsers();
    } else {
      const data = await res.json();
      errorMsg.value = data.detail || data.error || '删除用户失败';
    }
  } catch (err) {
    console.error(err);
    errorMsg.value = '请求失败，请检查网络';
  }
};

const openEdit = (user: User) => {
  editUser.value = user;
  editName.value = user.name;
  editUsername.value = user.username;
  editPassword.value = '';
  errorMsg.value = '';
  successMsg.value = '';
};

const handleEditSubmit = async () => {
  if (!editUser.value) return;
  errorMsg.value = '';
  successMsg.value = '';

  const body: Record<string, string> = {};
  if (editName.value !== editUser.value.name) {
    body.name = editName.value;
  }
  if (editUsername.value !== editUser.value.username) {
    body.username = editUsername.value;
  }
  if (editPassword.value) {
    body.password = editPassword.value;
  }
  if (Object.keys(body).length === 0) {
    errorMsg.value = '未检测到任何修改';
    return;
  }

  try {
    const res = await fetch(`/api/users/${editUser.value.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    const data = await res.json();
    if (res.ok) {
      successMsg.value = `成功修改用户 「${data.name}」`;
      editUser.value = null;
      fetchUsers();
    } else {
      errorMsg.value = data.error || '修改用户失败';
    }
  } catch (err) {
    console.error(err);
    errorMsg.value = '请求失败，请检查网络';
  }
};

onMounted(() => {
  fetchUsers();
});
</script>