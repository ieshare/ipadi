import AsyncStorage from '@react-native-async-storage/async-storage';

import { createSeedCases } from './seed';
import type { CaseItem } from './types';

const CASES_KEY = 'solodesk.cases.v1';

export async function loadCases(): Promise<CaseItem[]> {
  const raw = await AsyncStorage.getItem(CASES_KEY);
  if (!raw) {
    const seeded = createSeedCases();
    await AsyncStorage.setItem(CASES_KEY, JSON.stringify(seeded));
    return seeded;
  }
  try {
    const parsed = JSON.parse(raw) as CaseItem[];
    if (!Array.isArray(parsed)) return [];
    return parsed;
  } catch {
    const seeded = createSeedCases();
    await AsyncStorage.setItem(CASES_KEY, JSON.stringify(seeded));
    return seeded;
  }
}

export async function saveCases(cases: CaseItem[]): Promise<void> {
  await AsyncStorage.setItem(CASES_KEY, JSON.stringify(cases));
}
