/**
 * 东八区时间辅助函数(纯函数,便于测试)
 */

export function nowCST(): string {
  const parts = new Intl.DateTimeFormat('zh-CN', {
    timeZone: 'Asia/Shanghai',
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    hour12: false,
  }).formatToParts(new Date());
  const get = (type: string, fb = '00') => parts.find(p => p.type === type)?.value || fb;
  return `${get('year')}-${get('month')}-${get('day')}T${get('hour')}:${get('minute')}:${get('second')}+08:00`;
}

/** 将 ISO/数据库时间字符串格式化为东八区可读时间 */
export function formatCSTDisplay(iso?: string | null): string {
  if (!iso) return '—';
  const normalized = iso.trim().replace(' ', 'T');
  const hasOffset = /[Zz]$|[+-]\d{2}:\d{2}$/.test(normalized);
  const date = new Date(hasOffset ? normalized : `${normalized}+08:00`);
  if (Number.isNaN(date.getTime())) return iso;
  return new Intl.DateTimeFormat('zh-CN', {
    timeZone: 'Asia/Shanghai',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).format(date);
}

function parseCSTTimestamp(iso: string): number {
  const normalized = iso.trim().replace(' ', 'T');
  const hasOffset = /[Zz]$|[+-]\d{2}:\d{2}$/.test(normalized);
  return new Date(hasOffset ? normalized : `${normalized}+08:00`).getTime();
}

/** 最近一次事件是否为成功（成功时间 >= 失败时间） */
export function isLatestEventSuccess(lastSuccessAt?: string | null, lastFailureAt?: string | null): boolean {
  if (!lastSuccessAt) return false;
  if (!lastFailureAt) return true;
  const successTs = parseCSTTimestamp(lastSuccessAt);
  const failureTs = parseCSTTimestamp(lastFailureAt);
  if (Number.isNaN(successTs) || Number.isNaN(failureTs)) return false;
  return successTs >= failureTs;
}

export function todayCST(): string {
  const parts = new Intl.DateTimeFormat('zh-CN', {
    timeZone: 'Asia/Shanghai',
    year: 'numeric', month: '2-digit', day: '2-digit',
  }).formatToParts(new Date());
  const get = (type: string, fb = '01') => parts.find(p => p.type === type)?.value || fb;
  return `${get('year')}-${get('month')}-${get('day')}`;
}

/**
 * 获取当前东八区的小时数(0-23),用于调度判断
 */
export function currentCSTHour(): number {
  const hour = new Intl.DateTimeFormat('zh-CN', {
    timeZone: 'Asia/Shanghai',
    hour: '2-digit',
    hour12: false,
  }).format(new Date());
  return Number(hour);
}

/**
 * 获取当前东八区的 { hour, minute, dayOfWeek(0=周日, 1=周一...) }
 */
export function currentCSTClock(): { hour: number; minute: number; dayOfWeek: number } {
  const parts = new Intl.DateTimeFormat('zh-CN', {
    timeZone: 'Asia/Shanghai',
    hour: '2-digit', minute: '2-digit', weekday: 'short',
    hour12: false,
  }).formatToParts(new Date());
  const hour = Number(parts.find(p => p.type === 'hour')?.value || '0');
  const minute = Number(parts.find(p => p.type === 'minute')?.value || '0');
  const weekdayStr = parts.find(p => p.type === 'weekday')?.value || '';
  const weekdayMap: Record<string, number> = {
    '周日': 0, '周一': 1, '周二': 2, '周三': 3, '周四': 4, '周五': 5, '周六': 6,
  };
  return { hour, minute, dayOfWeek: weekdayMap[weekdayStr] ?? 1 };
}

/**
 * 判断目标日期字符串(YYYY-MM-DD)是否在 [from, to] 范围内
 * from/to 为空表示不限制
 */
export function isDateInRange(dateStr: string | undefined, from?: string, to?: string): boolean {
  if (!dateStr) return !from && !to;
  const date = dateStr.slice(0, 10);
  if (from && date < from.slice(0, 10)) return false;
  if (to && date > to.slice(0, 10)) return false;
  return true;
}
