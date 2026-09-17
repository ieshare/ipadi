import type { CaseItem } from './types';
import { endOfMonth, offsetDate } from './utils/dates';

export function createSeedCases(now = new Date()): CaseItem[] {
  const stamp = now.toISOString();
  const monthEnd = endOfMonth(now);

  return [
    {
      id: 'seed-nova-retainer',
      clientName: '株式会社ノヴァ',
      title: '技術顧問ライト',
      type: 'retainer',
      status: 'in_progress',
      amount: 120000,
      notes:
        '月2回の定例（各45〜60分）＋チャット質問（営業日48時間以内）。月8時間相当。超過は時給12,000円。相手はスタートアップのバックエンド担当。',
      nextAction: '定例アジェンダを送る（認証とジョブキューの論点）',
      nextMeetingDate: offsetDate(2, now),
      invoiceDueDate: monthEnd,
      createdAt: stamp,
      updatedAt: stamp,
    },
    {
      id: 'seed-kaede-short',
      clientName: '合同会社カエデ',
      title: '社内API 2週間パック',
      type: 'short',
      status: 'in_progress',
      amount: 320000,
      notes:
        '2週間で管理画面用BFFを納品。キックオフで要件固定済み。仕様変更は追加見積。',
      nextAction: 'エンドポイント一覧のドラフトを共有する',
      nextMeetingDate: offsetDate(1, now),
      invoiceDueDate: offsetDate(12, now),
      createdAt: stamp,
      updatedAt: stamp,
    },
    {
      id: 'seed-tanaka-spot',
      clientName: '田中（個人事業）',
      title: '60分壁打ち',
      type: 'spot',
      status: 'awaiting_invoice',
      amount: 15000,
      notes:
        'API設計とボトルネック切り分け。納品は議事メモ＋次アクション3つ。実施済み、請求のみ。',
      nextAction: '請求書を送付する',
      nextMeetingDate: null,
      invoiceDueDate: offsetDate(0, now),
      createdAt: stamp,
      updatedAt: stamp,
    },
    {
      id: 'seed-quill-proposal',
      clientName: 'Quill Inc.',
      title: '技術顧問ライト（提案）',
      type: 'retainer',
      status: 'proposal',
      amount: 120000,
      notes:
        '小規模プロダクトのCTO候補層。まずはスポット相談のあと継続を提案中。',
      nextAction: '提案書の範囲（月8時間／超過単価）を再送する',
      nextMeetingDate: offsetDate(5, now),
      invoiceDueDate: null,
      createdAt: stamp,
      updatedAt: stamp,
    },
    {
      id: 'seed-mizuki-done',
      clientName: '株式会社ミズキ',
      title: '既存APIの切り出し',
      type: 'short',
      status: 'done',
      amount: 280000,
      notes: '納品済み。同じ依頼が再発したらテンプレ化を検討する。',
      nextAction: '',
      nextMeetingDate: null,
      invoiceDueDate: offsetDate(-10, now),
      createdAt: stamp,
      updatedAt: stamp,
    },
  ];
}
