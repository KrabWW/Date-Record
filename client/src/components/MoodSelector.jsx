import React from 'react';

// 心情表情系统配置
const MOOD_OPTIONS = {
  amazing: { 
    emoji: '🥰', 
    label: '超开心', 
    color: '#FF6B9D',
    description: '今天太棒了！'
  },
  happy: { 
    emoji: '😊', 
    label: '很开心', 
    color: '#FF8FB3',
    description: '心情很好'
  },
  good: { 
    emoji: '😌', 
    label: '挺不错', 
    color: '#FFB3C6',
    description: '感觉还可以'
  },
  okay: { 
    emoji: '😐', 
    label: '一般般', 
    color: '#C4C4C4',
    description: '平平淡淡'
  },
  meh: { 
    emoji: '😕', 
    label: '不太好', 
    color: '#9E9E9E',
    description: '有点不开心'
  }
};

const MoodSelector = ({ 
  selectedMood = 'good', 
  onMoodChange, 
  size = 'medium',
  showLabels = true,
  disabled = false,
  className = '' 
}) => {
  const handleMoodSelect = (moodKey) => {
    if (disabled) return;
    onMoodChange && onMoodChange(moodKey);
  };

  const getSizeClasses = () => {
    switch (size) {
      case 'small':
        return {
          container: 'gap-2',
          button: 'w-8 h-8 text-lg',
          label: 'text-xs mt-1'
        };
      case 'large':
        return {
          container: 'gap-4',
          button: 'w-16 h-16 text-3xl',
          label: 'text-sm mt-2'
        };
      default: // medium
        return {
          container: 'gap-3',
          button: 'w-12 h-12 text-2xl',
          label: 'text-xs mt-1'
        };
    }
  };

  const sizeClasses = getSizeClasses();

  return (
    <div className={`flex justify-center ${sizeClasses.container} ${className}`}>
      {Object.entries(MOOD_OPTIONS).map(([moodKey, mood]) => {
        const isSelected = selectedMood === moodKey;
        
        return (
          <div key={moodKey} className="flex flex-col items-center">
            <button
              type="button"
              onClick={() => handleMoodSelect(moodKey)}
              disabled={disabled}
              className={`
                ${sizeClasses.button}
                rounded-full border-2 transition-all duration-200 
                flex items-center justify-center
                hover:scale-110 active:scale-95
                focus-visible:outline-2 focus-visible:outline-love-pink
                disabled:opacity-50 disabled:cursor-not-allowed
                ${isSelected 
                  ? `border-[${mood.color}] bg-[${mood.color}]/10 shadow-md` 
                  : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
                }
              `}
              style={{
                ...(isSelected && {
                  borderColor: mood.color,
                  backgroundColor: `${mood.color}15`
                })
              }}
              title={`${mood.label} - ${mood.description}`}
              aria-label={`选择心情: ${mood.label}`}
            >
              <span 
                className={`transform transition-transform duration-200 ${
                  isSelected ? 'animate-bounce' : ''
                }`}
              >
                {mood.emoji}
              </span>
            </button>
            
            {showLabels && (
              <span 
                className={`
                  ${sizeClasses.label} 
                  font-medium text-center transition-colors duration-200
                  ${isSelected ? 'text-gray-800' : 'text-gray-500'}
                `}
                style={{
                  ...(isSelected && { color: mood.color })
                }}
              >
                {mood.label}
              </span>
            )}
          </div>
        );
      })}
    </div>
  );
};

// 用于显示选中心情的简单组件
export const MoodDisplay = ({ mood, showLabel = true, size = 'medium' }) => {
  const moodConfig = MOOD_OPTIONS[mood];
  if (!moodConfig) return null;

  const getSizeClasses = () => {
    switch (size) {
      case 'small':
        return { emoji: 'text-base', label: 'text-xs ml-1' };
      case 'large':
        return { emoji: 'text-2xl', label: 'text-base ml-2' };
      default:
        return { emoji: 'text-xl', label: 'text-sm ml-1' };
    }
  };

  const sizeClasses = getSizeClasses();

  return (
    <div className="flex items-center">
      <span className={sizeClasses.emoji}>{moodConfig.emoji}</span>
      {showLabel && (
        <span 
          className={`font-medium ${sizeClasses.label}`}
          style={{ color: moodConfig.color }}
        >
          {moodConfig.label}
        </span>
      )}
    </div>
  );
};

// 导出心情选项配置，供其他组件使用
export { MOOD_OPTIONS };
export default MoodSelector;