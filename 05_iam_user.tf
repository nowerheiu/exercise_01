resource "aws_iam_user" "js_user" {
    name = "jingsheng"
}

resource "aws_iam_access_key" "js_user_access_key" {
  user = aws_iam_user.js_user.name
    
  depends_on = [aws_iam_user.js_user]
}

resource "aws_iam_user_policy_attachment" "js_user_attach_policy" {
    user       = aws_iam_user.js_user.name
    policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    depends_on = [aws_iam_user.js_user]
}