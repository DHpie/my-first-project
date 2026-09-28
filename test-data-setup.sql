-- 重置测试数据（确保 ID 从 1 开始）
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE messages;
TRUNCATE TABLE conversation_participants;
TRUNCATE TABLE conversations;
TRUNCATE TABLE notifications;
TRUNCATE TABLE user_blocks;
TRUNCATE TABLE user;

SET FOREIGN_KEY_CHECKS = 1;

-- Alice (id=1)
INSERT INTO user (uuid, username, email, nickname, bio, avatar_url, interest_tags, created_at, updated_at)
VALUES (UNHEX(REPLACE('00000000-0000-0000-0000-000000000001','-','')),
        'alice', 'alice@example.com', 'Alice', 'Love traveling and food!', NULL,
        '["Food","History","Nature"]', NOW(), NOW());

-- Bob (id=2)
INSERT INTO user (uuid, username, email, nickname, bio, avatar_url, interest_tags, created_at, updated_at)
VALUES (UNHEX(REPLACE('00000000-0000-0000-0000-000000000002','-','')),
        'bob', 'bob@example.com', 'Bob', 'Photography enthusiast', NULL,
        '["Photography","Adventure"]', NOW(), NOW());

-- Charlie (id=3)
INSERT INTO user (uuid, username, email, nickname, bio, avatar_url, interest_tags, created_at, updated_at)
VALUES (UNHEX(REPLACE('00000000-0000-0000-0000-000000000003','-','')),
        'charlie', 'charlie@example.com', 'Charlie', 'Music lover', NULL,
        '["Music","Culture"]', NOW(), NOW());

-- David (id=4)
INSERT INTO user (uuid, username, email, nickname, bio, avatar_url, interest_tags, created_at, updated_at)
VALUES (UNHEX(REPLACE('00000000-0000-0000-0000-000000000004','-','')),
        'david', 'david@example.com', 'David', 'New here', NULL,
        '["Shopping"]', NOW(), NOW());

-- Conversations
INSERT INTO conversations (uuid, user1_id, user2_id, last_message_at, created_at, updated_at)
VALUES (UNHEX(REPLACE('11111111-1111-1111-1111-111111111111','-','')), 1, 2, NOW(), NOW(), NOW());
INSERT INTO conversations (uuid, user1_id, user2_id, last_message_at, created_at, updated_at)
VALUES (UNHEX(REPLACE('22222222-2222-2222-2222-222222222222','-','')), 1, 3, DATE_SUB(NOW(), INTERVAL 1 HOUR), NOW(), NOW());

-- Participants
INSERT INTO conversation_participants (conversation_id, user_id, unread_count) VALUES (1, 1, 0);
INSERT INTO conversation_participants (conversation_id, user_id, unread_count) VALUES (1, 2, 2);
INSERT INTO conversation_participants (conversation_id, user_id, unread_count) VALUES (2, 1, 1);
INSERT INTO conversation_participants (conversation_id, user_id, unread_count) VALUES (2, 3, 0);

-- Messages
INSERT INTO messages (uuid, conversation_id, sender_id, content, created_at, updated_at) VALUES
(UNHEX(REPLACE('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1','-','')), 1, 2, 'Hey Alice! Have you seen the new exhibition?', DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR)),
(UNHEX(REPLACE('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2','-','')), 1, 1, 'Not yet! Is it good?', DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR)),
(UNHEX(REPLACE('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3','-','')), 1, 2, 'Absolutely! The photography section is amazing.', DATE_SUB(NOW(), INTERVAL 30 MINUTE), DATE_SUB(NOW(), INTERVAL 30 MINUTE)),
(UNHEX(REPLACE('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4','-','')), 1, 2, 'We should go together this weekend!', NOW(), NOW());

INSERT INTO messages (uuid, conversation_id, sender_id, content, created_at, updated_at) VALUES
(UNHEX(REPLACE('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1','-','')), 2, 1, 'Hi Charlie, love your music recommendations!', DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR)),
(UNHEX(REPLACE('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2','-','')), 2, 3, 'Thanks Alice! Have you listened to the new album?', DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR));

-- Notifications
INSERT INTO notifications (uuid, user_id, actor_id, type, target_type, target_id, content_snippet, is_read, is_content_deleted, created_at, updated_at) VALUES
(UNHEX(REPLACE('cccccccc-cccc-cccc-cccc-ccccccccccc1','-','')), 1, 2, 'LIKE', 'POST', 101, 'Bob liked your post about Great Wall', FALSE, FALSE, DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_SUB(NOW(), INTERVAL 5 HOUR)),
(UNHEX(REPLACE('cccccccc-cccc-cccc-cccc-ccccccccccc2','-','')), 1, 2, 'COMMENT', 'POST', 101, 'Bob commented: Amazing photo!', FALSE, FALSE, DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 4 HOUR)),
(UNHEX(REPLACE('cccccccc-cccc-cccc-cccc-ccccccccccc3','-','')), 1, 3, 'LIKE', 'POST', 102, 'Charlie liked your post about Food', TRUE, FALSE, DATE_SUB(NOW(), INTERVAL 24 HOUR), DATE_SUB(NOW(), INTERVAL 24 HOUR)),
(UNHEX(REPLACE('cccccccc-cccc-cccc-cccc-ccccccccccc4','-','')), 1, 3, 'REPLY', 'COMMENT', 201, 'Charlie replied to your comment', FALSE, FALSE, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR)),
(UNHEX(REPLACE('cccccccc-cccc-cccc-cccc-ccccccccccc5','-','')), 1, 2, 'LIKE', 'POST', 103, 'Bob liked your post about Temple', FALSE, FALSE, NOW(), NOW());

-- 验证
SELECT '=== Users ===' as section;
SELECT id, username, nickname FROM user ORDER BY id;
SELECT '=== Conversations ===' as section;
SELECT id, user1_id, user2_id FROM conversations;
SELECT '=== Participants ===' as section;
SELECT * FROM conversation_participants;
SELECT '=== Messages ===' as section;
SELECT id, conversation_id, sender_id, LEFT(content,30) as content FROM messages ORDER BY created_at;
SELECT '=== Notifications ===' as section;
SELECT id, user_id, actor_id, type, LEFT(content_snippet,30) as snippet, is_read FROM notifications ORDER BY created_at DESC;
