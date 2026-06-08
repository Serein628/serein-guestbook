-- ================================================================
-- Serein Guestbook — Supabase SQL Migration
-- ================================================================
-- 在 Supabase SQL Editor 中运行此文件来创建 comments 表
-- Run this in the Supabase SQL Editor to set up the comments table
-- ================================================================

-- 1. Create the comments table
CREATE TABLE IF NOT EXISTS public.comments (
  id         TEXT PRIMARY KEY,                -- client-generated: 'c_<ts>_<random>'
  author     TEXT NOT NULL,                   -- display name
  content    TEXT NOT NULL CHECK (char_length(content) <= 500),  -- max 500 chars
  ts         BIGINT NOT NULL,                -- Unix timestamp in milliseconds
  created_at TIMESTAMPTZ DEFAULT now()       -- server-side timestamp
);

-- 2. Enable Row Level Security
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies

-- Anyone can read all comments
CREATE POLICY "Anyone can read comments"
  ON public.comments
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Anyone can insert a comment (content length enforced by CHECK constraint)
CREATE POLICY "Anyone can insert comments"
  ON public.comments
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    char_length(content) > 0
    AND char_length(content) <= 500
    AND char_length(author) > 0
    AND char_length(author) <= 50
  );

-- Anyone can delete any comment (client UI restricts to own comments via localStorage identity)
-- For a stricter approach, switch to Supabase Auth and restrict by auth.uid()
CREATE POLICY "Anyone can delete comments"
  ON public.comments
  FOR DELETE
  TO anon, authenticated
  USING (true);

-- 4. Grant access to anon and authenticated roles
GRANT SELECT, INSERT, DELETE ON public.comments TO anon, authenticated;

-- 5. Enable realtime for live sync
ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;

-- 6. Indexes
CREATE INDEX IF NOT EXISTS idx_comments_ts ON public.comments (ts DESC);
CREATE INDEX IF NOT EXISTS idx_comments_author ON public.comments (author);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON public.comments (created_at DESC);

-- ================================================================
-- 可选 / Optional: 为 Supabase Auth 用户准备的更安全的策略
-- 如果你将来迁移到 Supabase Auth，可以用下面的策略替换上面的 DELETE 策略
-- ================================================================
-- DROP POLICY IF EXISTS "Anyone can delete comments" ON public.comments;
-- CREATE POLICY "Users can delete own comments"
--   ON public.comments
--   FOR DELETE
--   TO authenticated
--   USING (author = (SELECT raw_user_meta_data->>'display_name' FROM auth.users WHERE id = auth.uid()));

-- ================================================================
-- 可选 / Optional: 清理测试数据
-- TRUNCATE TABLE public.comments;
-- ================================================================
