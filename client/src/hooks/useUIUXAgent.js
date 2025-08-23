import { useEffect, useRef, useState } from 'react';
import UIUXAgent from '../agents/UIUXAgent';

export const useUIUXAgent = (config = {}) => {
  const agentRef = useRef(null);
  const [optimizations, setOptimizations] = useState([]);
  const [report, setReport] = useState(null);
  const [isEnabled, setIsEnabled] = useState(true);

  useEffect(() => {
    if (!isEnabled) return;

    agentRef.current = new UIUXAgent({
      debugMode: process.env.NODE_ENV === 'development',
      ...config
    });

    const handleOptimization = (event) => {
      setOptimizations(prev => [...prev, event.detail]);
    };

    document.addEventListener('uiux-optimization', handleOptimization);

    return () => {
      document.removeEventListener('uiux-optimization', handleOptimization);
      agentRef.current?.destroy();
    };
  }, [isEnabled, config]);

  const generateReport = () => {
    if (agentRef.current) {
      const newReport = agentRef.current.getOptimizationReport();
      setReport(newReport);
      return newReport;
    }
  };

  const applyOptimizations = (optimizationsToApply) => {
    if (agentRef.current) {
      return agentRef.current.applyOptimizations(optimizationsToApply);
    }
  };

  const getAccessibilityScore = (element) => {
    if (agentRef.current && element) {
      return agentRef.current.getAccessibilityScore(element);
    }
  };

  const optimizeForMobile = () => {
    if (agentRef.current) {
      return agentRef.current.optimizeForMobile();
    }
  };

  return {
    agent: agentRef.current,
    optimizations,
    report,
    isEnabled,
    setIsEnabled,
    generateReport,
    applyOptimizations,
    getAccessibilityScore,
    optimizeForMobile
  };
};

export default useUIUXAgent;