# 后端开发规范

## 分层架构

```
Controller -> Service(接口) -> ServiceImpl -> Repository -> Entity
                                  |
                            Mapper (静态方法)
                            DTO (request/response)
```

- **Controller**: 接收请求，参数校验，调用 Service，返回 `Result<T>`
- **Service**: 业务接口定义
- **ServiceImpl**: 业务逻辑实现
- **Repository**: 数据访问 (Spring Data JPA)
- **Entity**: JPA 实体，映射数据库表
- **DTO**: 入站 (请求) / 出站 (响应) 数据传输对象
- **Mapper**: Entity 与 DTO 之间的手动映射

## Controller 规范

- `@RestController` + `@RequestMapping("/api/xxx")`
- `@RequiredArgsConstructor` 构造器注入 Service
- 所有返回值用 `Result<T>` 包装
- 入参校验用 `@Valid` + DTO 上的 Jakarta Validation 注解
- RESTful 风格: GET / POST / PUT / DELETE

```java
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;

    @PostMapping
    public Result<UserResponse> createUser(@Valid @RequestBody UserCreateRequest request) {
        return Result.success(userService.createUser(request));
    }
}
```

## Service 规范

- 接口定义在 `service/`，实现在 `service/impl/`
- 接口名: `XxxService`，实现名: `XxxServiceImpl`
- `@Service` + `@RequiredArgsConstructor`
- 写操作 `@Transactional`，只读 `@Transactional(readOnly = true)`
- 未找到实体时抛出 `EntityNotFoundException`

## DTO 规范

- **Request DTO**: `dto/request/XxxRequest.java`
  - `@Data` + Jakarta Validation 注解 (`@NotBlank`, `@Email`, `@Size` 等)
- **Response DTO**: `dto/response/XxxResponse.java`
  - `@Data` + `@NoArgsConstructor` + `@AllArgsConstructor`
- **禁止**直接暴露 Entity 给 Controller 层

## Mapper 规范

- 手动映射类，私有构造器 + 静态方法
- 三个标准方法:
  - `toEntity(XxxRequest request)` -- 请求 -> 实体
  - `toResponse(Xxx entity)` -- 实体 -> 响应
  - `updateEntity(Xxx entity, XxxUpdateRequest request)` -- 部分更新
- 不使用 MapStruct (保持简单，AI 训练数据覆盖充分)

```java
public class UserMapper {
    private UserMapper() {}

    public static User toEntity(UserCreateRequest request) { ... }
    public static UserResponse toResponse(User user) { ... }
    public static void updateEntity(User user, UserUpdateRequest request) { ... }
}
```

## 统一响应格式

```java
Result<T> {
    int code;        // 业务状态码
    String message;  // 描述信息
    T data;          // 业务数据
}
```

- `Result.success(data)` / `Result.success()` / `Result.error(ResultCode)`
- `ResultCode` 枚举:
  - `SUCCESS(200, "success")` -- 成功
  - `BAD_REQUEST(400, "Bad Request")` -- 请求参数错误
  - `NOT_FOUND(404, "Not Found")` -- 资源未找到
  - `INTERNAL_ERROR(500, "Internal Server Error")` -- 服务器内部错误
- 业务异常可通过扩展 `ResultCode` 枚举或 `Result.error(int code, String message)` 处理

## 异常处理

- `GlobalExceptionHandler` (`@RestControllerAdvice`) 统一拦截
- `MethodArgumentNotValidException` -> 400 + 拼接字段错误消息
- `EntityNotFoundException` -> 404
- `Exception` -> 500 (兜底)
- 新增业务异常类型时，在 `GlobalExceptionHandler` 中添加对应的 `@ExceptionHandler` 方法

## API 路径规范

- 所有端点 `/api` 前缀
- RESTful 风格:
  - 集合: `GET /api/xxx`
  - 单个: `GET /api/xxx/{id}`
  - 创建: `POST /api/xxx`
  - 更新: `PUT /api/xxx/{id}`
  - 删除: `DELETE /api/xxx/{id}`
