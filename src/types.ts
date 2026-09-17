export const CASE_TYPES = ['retainer', 'short', 'spot'] as const;
export type CaseType = (typeof CASE_TYPES)[number];

export const CASE_STATUSES = [
  'proposal',
  'in_progress',
  'awaiting_invoice',
  'done',
] as const;
export type CaseStatus = (typeof CASE_STATUSES)[number];

export type CaseItem = {
  id: string;
  clientName: string;
  title: string;
  type: CaseType;
  status: CaseStatus;
  amount: number;
  notes: string;
  nextAction: string;
  nextMeetingDate: string | null;
  invoiceDueDate: string | null;
  createdAt: string;
  updatedAt: string;
};

export type CaseDraft = Omit<CaseItem, 'id' | 'createdAt' | 'updatedAt'>;
