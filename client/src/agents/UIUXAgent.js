class UIUXAgent {
  constructor(options = {}) {
    this.config = {
      trackInteractions: options.trackInteractions ?? true,
      analyzePerformance: options.analyzePerformance ?? true,
      optimizeUI: options.optimizeUI ?? true,
      debugMode: options.debugMode ?? false,
      ...options
    };
    
    this.interactionData = new Map();
    this.performanceMetrics = new Map();
    this.uiOptimizations = new Map();
    this.userPreferences = new Map();
    
    this.init();
  }

  init() {
    if (this.config.trackInteractions) {
      this.setupInteractionTracking();
    }
    
    if (this.config.analyzePerformance) {
      this.setupPerformanceMonitoring();
    }
    
    this.loadUserPreferences();
  }

  setupInteractionTracking() {
    const trackEvent = (event) => {
      const target = event.target;
      const eventData = {
        timestamp: Date.now(),
        type: event.type,
        element: target.tagName.toLowerCase(),
        className: target.className,
        id: target.id,
        content: target.textContent?.substring(0, 50),
        position: { x: event.clientX, y: event.clientY },
        viewport: { width: window.innerWidth, height: window.innerHeight }
      };

      const key = `${eventData.element}-${eventData.className}-${eventData.id}`;
      if (!this.interactionData.has(key)) {
        this.interactionData.set(key, []);
      }
      this.interactionData.get(key).push(eventData);

      this.analyzeInteractionPattern(key, eventData);
    };

    ['click', 'hover', 'focus', 'scroll', 'touchstart'].forEach(eventType => {
      document.addEventListener(eventType, trackEvent, true);
    });
  }

  setupPerformanceMonitoring() {
    const observer = new PerformanceObserver((list) => {
      list.getEntries().forEach((entry) => {
        this.performanceMetrics.set(entry.name, {
          ...entry,
          timestamp: Date.now()
        });
      });
    });

    observer.observe({ entryTypes: ['measure', 'navigation', 'paint'] });

    setInterval(() => {
      this.analyzePerformanceMetrics();
    }, 5000);
  }

  analyzeInteractionPattern(key, eventData) {
    const interactions = this.interactionData.get(key);
    if (interactions.length < 2) return;

    const recent = interactions.slice(-10);
    const avgTimeBetween = this.calculateAverageTimeBetween(recent);
    const clickHeatmap = this.generateClickHeatmap(recent);

    if (avgTimeBetween < 500) {
      this.suggestOptimization(key, {
        type: 'rapid-clicking',
        suggestion: 'Consider adding debouncing or loading states',
        priority: 'high'
      });
    }

    if (this.detectFrustrationPattern(recent)) {
      this.suggestOptimization(key, {
        type: 'user-frustration',
        suggestion: 'Element may be confusing or unresponsive',
        priority: 'critical'
      });
    }
  }

  detectFrustrationPattern(interactions) {
    if (interactions.length < 5) return false;

    const rapidClicks = interactions.filter((current, index) => {
      if (index === 0) return false;
      const prev = interactions[index - 1];
      return current.timestamp - prev.timestamp < 300;
    });

    return rapidClicks.length >= 3;
  }

  calculateAverageTimeBetween(interactions) {
    if (interactions.length < 2) return 0;

    const times = interactions.slice(1).map((current, index) => 
      current.timestamp - interactions[index].timestamp
    );

    return times.reduce((sum, time) => sum + time, 0) / times.length;
  }

  generateClickHeatmap(interactions) {
    const heatmap = {};
    interactions.forEach(interaction => {
      const zone = this.getScreenZone(interaction.position);
      heatmap[zone] = (heatmap[zone] || 0) + 1;
    });
    return heatmap;
  }

  getScreenZone(position) {
    const { x, y } = position;
    const centerX = window.innerWidth / 2;
    const centerY = window.innerHeight / 2;

    if (x < centerX && y < centerY) return 'top-left';
    if (x >= centerX && y < centerY) return 'top-right';
    if (x < centerX && y >= centerY) return 'bottom-left';
    return 'bottom-right';
  }

  analyzePerformanceMetrics() {
    const metrics = Array.from(this.performanceMetrics.values());
    const recentMetrics = metrics.filter(m => Date.now() - m.timestamp < 30000);

    const slowOperations = recentMetrics.filter(m => m.duration > 100);
    if (slowOperations.length > 0) {
      this.suggestOptimization('performance', {
        type: 'slow-operations',
        operations: slowOperations,
        suggestion: 'Consider optimizing these slow operations',
        priority: 'medium'
      });
    }
  }

  suggestOptimization(key, optimization) {
    if (!this.uiOptimizations.has(key)) {
      this.uiOptimizations.set(key, []);
    }

    const existing = this.uiOptimizations.get(key);
    const isDuplicate = existing.some(opt => opt.type === optimization.type);
    
    if (!isDuplicate) {
      existing.push({
        ...optimization,
        timestamp: Date.now(),
        id: Math.random().toString(36).substr(2, 9)
      });

      if (this.config.debugMode) {
        console.log(`UI/UX Optimization Suggestion for ${key}:`, optimization);
      }

      this.notifyOptimization(key, optimization);
    }
  }

  notifyOptimization(key, optimization) {
    const event = new CustomEvent('uiux-optimization', {
      detail: { key, optimization }
    });
    document.dispatchEvent(event);
  }

  getAccessibilityScore(element) {
    let score = 100;
    const issues = [];

    if (!element.getAttribute('aria-label') && !element.textContent) {
      score -= 20;
      issues.push('Missing accessible label');
    }

    const contrastRatio = this.calculateContrastRatio(element);
    if (contrastRatio < 4.5) {
      score -= 15;
      issues.push('Insufficient color contrast');
    }

    if (element.tagName === 'BUTTON' && !element.getAttribute('aria-describedby')) {
      score -= 10;
      issues.push('Button lacks description');
    }

    return { score, issues };
  }

  calculateContrastRatio(element) {
    const styles = window.getComputedStyle(element);
    const bgColor = styles.backgroundColor;
    const textColor = styles.color;

    const bg = this.parseColor(bgColor);
    const text = this.parseColor(textColor);

    if (!bg || !text) return 21;

    const bgLuminance = this.getLuminance(bg);
    const textLuminance = this.getLuminance(text);

    const lighter = Math.max(bgLuminance, textLuminance);
    const darker = Math.min(bgLuminance, textLuminance);

    return (lighter + 0.05) / (darker + 0.05);
  }

  parseColor(color) {
    const rgb = color.match(/\d+/g);
    if (!rgb || rgb.length < 3) return null;
    return rgb.slice(0, 3).map(Number);
  }

  getLuminance([r, g, b]) {
    const [rs, gs, bs] = [r, g, b].map(c => {
      c = c / 255;
      return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
  }

  optimizeForMobile() {
    const isMobile = window.innerWidth <= 768;
    if (!isMobile) return;

    const optimizations = [];

    document.querySelectorAll('button, a, [data-clickable]').forEach(element => {
      const rect = element.getBoundingClientRect();
      if (rect.width < 44 || rect.height < 44) {
        optimizations.push({
          element,
          issue: 'Touch target too small',
          suggestion: 'Increase minimum touch target to 44px'
        });
      }
    });

    document.querySelectorAll('input, textarea, select').forEach(element => {
      if (element.getAttribute('inputmode') === null) {
        optimizations.push({
          element,
          issue: 'Missing inputmode attribute',
          suggestion: 'Add appropriate inputmode for better mobile keyboard'
        });
      }
    });

    return optimizations;
  }

  generateUserPersona() {
    const interactions = Array.from(this.interactionData.values()).flat();
    const preferences = Array.from(this.userPreferences.entries());

    const avgSessionTime = this.calculateAverageSessionTime();
    const preferredInteractionZones = this.getMostUsedZones();
    const deviceType = window.innerWidth <= 768 ? 'mobile' : 'desktop';

    return {
      sessionDuration: avgSessionTime,
      preferredZones: preferredInteractionZones,
      deviceType,
      interactionFrequency: interactions.length,
      preferences: Object.fromEntries(preferences),
      timestamp: Date.now()
    };
  }

  calculateAverageSessionTime() {
    const sessionStart = Math.min(...Array.from(this.interactionData.values())
      .flat().map(i => i.timestamp));
    return Date.now() - sessionStart;
  }

  getMostUsedZones() {
    const zones = {};
    Array.from(this.interactionData.values()).flat().forEach(interaction => {
      const zone = this.getScreenZone(interaction.position);
      zones[zone] = (zones[zone] || 0) + 1;
    });

    return Object.entries(zones)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 2)
      .map(([zone]) => zone);
  }

  loadUserPreferences() {
    try {
      const saved = localStorage.getItem('uiux-preferences');
      if (saved) {
        const preferences = JSON.parse(saved);
        Object.entries(preferences).forEach(([key, value]) => {
          this.userPreferences.set(key, value);
        });
      }
    } catch (error) {
      console.warn('Failed to load UI/UX preferences:', error);
    }
  }

  saveUserPreferences() {
    try {
      const preferences = Object.fromEntries(this.userPreferences);
      localStorage.setItem('uiux-preferences', JSON.stringify(preferences));
    } catch (error) {
      console.warn('Failed to save UI/UX preferences:', error);
    }
  }

  getOptimizationReport() {
    const report = {
      timestamp: Date.now(),
      interactions: this.interactionData.size,
      optimizations: Array.from(this.uiOptimizations.entries()).map(([key, opts]) => ({
        element: key,
        suggestions: opts
      })),
      performance: Array.from(this.performanceMetrics.values()),
      userPersona: this.generateUserPersona()
    };

    return report;
  }

  applyOptimizations(optimizations) {
    const applied = [];

    optimizations.forEach(opt => {
      try {
        switch (opt.type) {
          case 'add-loading-state':
            this.addLoadingState(opt.element);
            applied.push(opt);
            break;
          
          case 'improve-contrast':
            this.improveContrast(opt.element);
            applied.push(opt);
            break;
          
          case 'resize-touch-target':
            this.resizeTouchTarget(opt.element);
            applied.push(opt);
            break;
        }
      } catch (error) {
        console.warn('Failed to apply optimization:', opt, error);
      }
    });

    return applied;
  }

  addLoadingState(element) {
    if (!element.dataset.originalText) {
      element.dataset.originalText = element.textContent;
    }

    element.addEventListener('click', () => {
      element.disabled = true;
      element.textContent = '加载中...';
      element.classList.add('loading');

      setTimeout(() => {
        element.disabled = false;
        element.textContent = element.dataset.originalText;
        element.classList.remove('loading');
      }, 2000);
    });
  }

  improveContrast(element) {
    const styles = window.getComputedStyle(element);
    const bgColor = styles.backgroundColor;
    const textColor = styles.color;

    if (this.calculateContrastRatio(element) < 4.5) {
      element.style.filter = 'contrast(1.2)';
    }
  }

  resizeTouchTarget(element) {
    const rect = element.getBoundingClientRect();
    if (rect.width < 44) {
      element.style.minWidth = '44px';
    }
    if (rect.height < 44) {
      element.style.minHeight = '44px';
    }
    element.style.padding = Math.max(8, parseInt(styles.padding) || 0) + 'px';
  }

  destroy() {
    this.saveUserPreferences();
    this.interactionData.clear();
    this.performanceMetrics.clear();
    this.uiOptimizations.clear();
  }
}

export default UIUXAgent;