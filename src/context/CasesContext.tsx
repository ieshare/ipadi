import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';

import { loadCases, saveCases } from '../storage';
import type { CaseDraft, CaseItem } from '../types';
import { createId } from '../utils/format';

type CasesContextValue = {
  cases: CaseItem[];
  loading: boolean;
  getCase: (id: string) => CaseItem | undefined;
  addCase: (draft: CaseDraft) => Promise<CaseItem>;
  updateCase: (id: string, draft: CaseDraft) => Promise<void>;
  deleteCase: (id: string) => Promise<void>;
};

const CasesContext = createContext<CasesContextValue | null>(null);

export function CasesProvider({ children }: { children: ReactNode }) {
  const [cases, setCases] = useState<CaseItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const loaded = await loadCases();
      if (!cancelled) {
        setCases(loaded);
        setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const persist = useCallback(async (next: CaseItem[]) => {
    setCases(next);
    await saveCases(next);
  }, []);

  const getCase = useCallback(
    (id: string) => cases.find((item) => item.id === id),
    [cases],
  );

  const addCase = useCallback(
    async (draft: CaseDraft) => {
      const now = new Date().toISOString();
      const created: CaseItem = {
        ...draft,
        id: createId(),
        createdAt: now,
        updatedAt: now,
      };
      await persist([created, ...cases]);
      return created;
    },
    [cases, persist],
  );

  const updateCase = useCallback(
    async (id: string, draft: CaseDraft) => {
      const now = new Date().toISOString();
      await persist(
        cases.map((item) =>
          item.id === id ? { ...item, ...draft, updatedAt: now } : item,
        ),
      );
    },
    [cases, persist],
  );

  const deleteCase = useCallback(
    async (id: string) => {
      await persist(cases.filter((item) => item.id !== id));
    },
    [cases, persist],
  );

  const value = useMemo(
    () => ({ cases, loading, getCase, addCase, updateCase, deleteCase }),
    [cases, loading, getCase, addCase, updateCase, deleteCase],
  );

  return <CasesContext.Provider value={value}>{children}</CasesContext.Provider>;
}

export function useCases(): CasesContextValue {
  const ctx = useContext(CasesContext);
  if (!ctx) {
    throw new Error('useCases must be used within CasesProvider');
  }
  return ctx;
}
