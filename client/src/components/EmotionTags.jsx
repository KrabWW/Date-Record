import React from 'react';

// 情感标签配置
const EMOTION_TAGS = [
  { id: 'romantic', label: '浪漫', emoji: '💕', color: '#FF69B4' },
  { id: 'fun', label: '有趣', emoji: '😄', color: '#FFA500' },
  { id: 'peaceful', label: '安静', emoji: '😌', color: '#87CEEB' },
  { id: 'exciting', label: '刺激', emoji: '🤩', color: '#FF4500' },
  { id: 'cozy', label: '温馨', emoji: '🤗', color: '#DDA0DD' },
  { id: 'adventurous', label: '冒险', emoji: '🌟', color: '#32CD32' },
  { id: 'relaxing', label: '放松', emoji: '😊', color: '#98FB98' },
  { id: 'sweet', label: '甜蜜', emoji: '🍯', color: '#FFB6C1' },
  { id: 'surprise', label: '惊喜', emoji: '🎉', color: '#FF6347' },
  { id: 'intimate', label: '亲密', emoji: '💑', color: '#DA70D6' },
  { id: 'sweetness_overload', label: '甜度爆表', emoji: '🍭', color: '#FF1493' },
  { id: 'heart_flutter', label: '小鹿乱撞', emoji: '🦌', color: '#FF69B4' },
  { id: 'roller_coaster', label: '过山车', emoji: '🎢', color: '#FF4500' },
  { id: 'after_rain', label: '雨过天晴', emoji: '🌈', color: '#87CEEB' },
  { id: 'healing', label: '治愈', emoji: '🌱', color: '#90EE90' },
  { id: 'looking_forward', label: '期待再见', emoji: '🤗', color: '#DDA0DD' },
  { id: 'disappointing', label: '下头', emoji: '😮‍💨', color: '#708090' }
];

const EmotionTags = ({ 
  selectedTags = [], 
  onTagsChange, 
  maxTags = 3,
  disabled = false,
  className = '',
  showEmojis = true 
}) => {
  const handleTagToggle = (tagId) => {
    if (disabled) return;

    let newTags;
    if (selectedTags.includes(tagId)) {
      // 移除标签
      newTags = selectedTags.filter(id => id !== tagId);
    } else {
      // 添加标签（检查最大数量限制）
      if (selectedTags.length >= maxTags) {
        return; // 达到最大数量，不添加
      }
      newTags = [...selectedTags, tagId];
    }
    
    onTagsChange && onTagsChange(newTags);
  };

  return (
    <div className={`space-y-3 ${className}`}>
      {maxTags > 1 && (
        <div className="text-sm text-gray-600">
          选择情感标签 (最多{maxTags}个) {selectedTags.length > 0 && `- 已选 ${selectedTags.length}/${maxTags}`}
        </div>
      )}
      
      <div className="flex flex-wrap gap-2">
        {EMOTION_TAGS.map((tag) => {
          const isSelected = selectedTags.includes(tag.id);
          const canSelect = selectedTags.length < maxTags || isSelected;
          
          return (
            <button
              key={tag.id}
              type="button"
              onClick={() => handleTagToggle(tag.id)}
              disabled={disabled || !canSelect}
              className={`
                inline-flex items-center px-3 py-2 rounded-full text-sm font-medium
                transition-all duration-200 border-2
                hover:scale-105 active:scale-95
                focus-visible:outline-2 focus-visible:outline-love-pink focus-visible:outline-offset-2
                disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none
                ${isSelected 
                  ? 'text-white shadow-md transform scale-105' 
                  : canSelect
                    ? 'text-gray-700 border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50'
                    : 'text-gray-400 border-gray-100 bg-gray-50'
                }
              `}
              style={{
                ...(isSelected && {
                  backgroundColor: tag.color,
                  borderColor: tag.color
                })
              }}
              title={`${isSelected ? '取消选择' : '选择'} ${tag.label} 情感标签`}
              aria-label={`${isSelected ? '取消选择' : '选择'} ${tag.label} 情感标签`}
            >
              {showEmojis && (
                <span className="mr-1 text-base">{tag.emoji}</span>
              )}
              <span>{tag.label}</span>
              {isSelected && (
                <span className="ml-1 text-xs opacity-75">✓</span>
              )}
            </button>
          );
        })}
      </div>
      
      {selectedTags.length === maxTags && (
        <div className="text-xs text-amber-600 bg-amber-50 px-3 py-2 rounded-lg">
          💡 已达到最大标签数量，取消选择一个标签后可选择其他标签
        </div>
      )}
    </div>
  );
};

// 用于显示选中标签的简单组件
export const EmotionTagsDisplay = ({ 
  tags = [], 
  showEmojis = true, 
  size = 'small',
  maxDisplay = 3 
}) => {
  if (!tags || tags.length === 0) return null;

  const displayTags = tags.slice(0, maxDisplay);
  const remainingCount = tags.length - maxDisplay;

  const getSizeClasses = () => {
    switch (size) {
      case 'large':
        return 'px-3 py-2 text-sm';
      case 'medium':
        return 'px-2 py-1 text-sm';
      default: // small
        return 'px-2 py-1 text-xs';
    }
  };

  const sizeClasses = getSizeClasses();

  return (
    <div className="flex flex-wrap gap-1">
      {displayTags.map((tagId) => {
        const tag = EMOTION_TAGS.find(t => t.id === tagId);
        if (!tag) return null;

        return (
          <span
            key={tagId}
            className={`
              inline-flex items-center rounded-full font-medium
              ${sizeClasses}
            `}
            style={{
              backgroundColor: `${tag.color}20`,
              color: tag.color
            }}
          >
            {showEmojis && (
              <span className="mr-1">{tag.emoji}</span>
            )}
            {tag.label}
          </span>
        );
      })}
      
      {remainingCount > 0 && (
        <span className={`
          inline-flex items-center rounded-full font-medium bg-gray-100 text-gray-600
          ${sizeClasses}
        `}>
          +{remainingCount}
        </span>
      )}
    </div>
  );
};

// 导出情感标签配置，供其他组件使用
export { EMOTION_TAGS };
export default EmotionTags;