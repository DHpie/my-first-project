## MODIFIED Requirements

### Requirement: Sticky Header
系统 SHALL 在首页顶部渲染 sticky header，包含品牌 logo（左侧）和功能组件（右侧）。

#### Scenario: Header 布局
- **WHEN** 首页渲染完成
- **THEN** Header SHALL 包含品牌 logo 链接（左侧）、AI assistant 导航链接（右侧）、`NotificationBell` 组件（右侧，需登录后显示）
- **AND** Header SHALL 为 `sticky top-0 z-50`

#### Scenario: Header 品牌渐变底边
- **WHEN** Header 渲染完成
- **THEN** Header 底部 SHALL 显示品牌渐变装饰线（`bg-gradient-to-r from-[#C41E3A] via-[#D4A017] to-[#C41E3A]`，高度 2px）
