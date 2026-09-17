export const colors = {
  bg: '#F3EEE4',
  paper: '#FFFBF5',
  ink: '#1B2420',
  muted: '#5C6B64',
  line: '#E4D9C8',
  teal: '#1F6F64',
  tealSoft: '#E4F1EE',
  navy: '#2C3E6B',
  navySoft: '#E8ECF5',
  amber: '#C4841D',
  amberSoft: '#F8EED9',
  copper: '#B85C38',
  copperSoft: '#F6E6DC',
  slate: '#6B7280',
  slateSoft: '#EEF0F2',
  done: '#6E7F6E',
  doneSoft: '#E7EEE7',
  danger: '#9B3A32',
  white: '#FFFFFF',
};

export const typeMeta: Record<
  'retainer' | 'short' | 'spot',
  { label: string; color: string; soft: string }
> = {
  retainer: { label: '顧問', color: colors.teal, soft: colors.tealSoft },
  short: { label: '短期実装', color: colors.navy, soft: colors.navySoft },
  spot: { label: 'スポット', color: colors.amber, soft: colors.amberSoft },
};

export const statusMeta: Record<
  'proposal' | 'in_progress' | 'awaiting_invoice' | 'done',
  { label: string; color: string; soft: string }
> = {
  proposal: { label: '提案中', color: colors.slate, soft: colors.slateSoft },
  in_progress: { label: '進行中', color: colors.teal, soft: colors.tealSoft },
  awaiting_invoice: {
    label: '請求待ち',
    color: colors.copper,
    soft: colors.copperSoft,
  },
  done: { label: '完了', color: colors.done, soft: colors.doneSoft },
};

export const amountKindLabel: Record<'retainer' | 'short' | 'spot', string> = {
  retainer: '月額',
  short: '見積',
  spot: '単価',
};
