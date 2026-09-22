# 数据库开发规范

## Entity 基类 (BaseEntity)

所有实体必须继承 `@MappedSuperclass` 标注的 `BaseEntity` 抽象类。

### BaseEntity 字段设计

| 字段 | 类型 | 注解 | 说明 |
|------|------|------|------|
| `id` | `Long` | `@Id @GeneratedValue(IDENTITY)` | 内部主键，不暴露给 API |
| `uuid` | `UUID` | `@Column(unique=true, nullable=false)` | 外部标识，API 路径使用此字段 |
| `createdAt` | `LocalDateTime` | `@Column(updatable=false)` | `@PrePersist` 自动设置 |
| `updatedAt` | `LocalDateTime` | `@Column` | `@PreUpdate` 自动更新 |

### 主键策略

- **Long id**: 内部主键，用于 JPA 关联和连接查询，性能最优
- **UUID uuid**: 外部接口标识，不可预测，防止枚举攻击和数量暴露
- API 路径示例: `GET /api/users/{uuid}` (非 `/api/users/{id}`)

### 时间戳自动化

```java
@PrePersist
protected void onCreate() {
    if (uuid == null) uuid = UUID.randomUUID();
    this.createdAt = LocalDateTime.now();
    this.updatedAt = LocalDateTime.now();
}

@PreUpdate
protected void onUpdate() {
    this.updatedAt = LocalDateTime.now();
}
```

## Entity 编码规范

- `@Entity` + `@Table(name = "xxx")`
- 使用 Lombok: `@Data`, `@NoArgsConstructor`, `@AllArgsConstructor`
- 字段用 `@Column` 明确约束 (`nullable`, `length`, `unique`)
- 继承 `BaseEntity` 获取公共字段

## 命名规范

| 数据库 | Java Entity | API |
|--------|-------------|-----|
| 表名 `snake_case` | 类名 `PascalCase` | 路径 `kebab-case` |
| 列名 `snake_case` | 字段名 `camelCase` | JSON `camelCase` |
| `created_at` | `createdAt` | `createdAt` |
| `updated_at` | `updatedAt` | `updatedAt` |

## Repository 规范

- 继承 `JpaRepository<XxxEntity, Long>`
- 接口放 `repository/` 目录
- 自定义查询用 Spring Data 方法命名派生或 `@Query`
- `@Repository` 注解 (可选，Spring Data 自动识别)

## 注意事项

- 新实体创建时，先确认是否需要软删除 (`deleted` 字段) -- 按需引入 (YAGNI 原则)，不提前设计
- UUID 在 `@PrePersist` 中生成，确保 `if (uuid == null)` 保护
- 所有实体公共字段通过 `BaseEntity` 继承，不在子类中重复定义
