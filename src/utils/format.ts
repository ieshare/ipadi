import type { CaseItem } from '../types';

export function formatYen(amount: number): string {
  return `¥${Math.round(amount).toLocaleString('ja-JP')}`;
}

export function createId(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
}

export function sortCases(cases: CaseItem[]): CaseItem[] {
  const rank: Record<CaseItem['status'], number> = {
    awaiting_invoice: 0,
    in_progress: 1,
    proposal: 2,
    done: 3,
  };
  return [...cases].sort((a, b) => {
    const r = rank[a.status] - rank[b.status];
    if (r !== 0) return r;
    return b.updatedAt.localeCompare(a.updatedAt);
  });
}

export function projectedRevenue(cases: CaseItem[]): number {
  return cases
    .filter((c) => c.status === 'in_progress' || c.status === 'awaiting_invoice')
    .reduce((sum, c) => sum + c.amount, 0);
}
