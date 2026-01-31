# GitHub Actions Workflows

## Wymagane Secrets

Aby workflow działał, musisz skonfigurować następujące secrets w GitHub:

1. **AWS_ACCESS_KEY_ID** - AWS Access Key ID
2. **AWS_SECRET_ACCESS_KEY** - AWS Secret Access Key
3. **CODECOV_TOKEN** - Codecov repository upload token (opcjonalne, ale zalecane aby uniknąć rate limits)

### Jak skonfigurować secrets:

1. Przejdź do Settings → Secrets and variables → Actions w Twoim repozytorium GitHub
2. Kliknij "New repository secret"
3. Dodaj secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `CODECOV_TOKEN` (opcjonalne - pobierz z https://codecov.io → Settings → General → Repository Upload Token)

### Tworzenie użytkownika IAM dla GitHub Actions:

```bash
# Utwórz użytkownika IAM
aws iam create-user --user-name github-actions-deploy

# Utwórz policy z wymaganymi uprawnieniami
cat > ecr-ecs-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeServices"
      ],
      "Resource": "arn:aws:ecs:eu-central-1:*:service/fastapi-app-cluster/fastapi-app-service"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeTasks",
        "ecs:ListTasks"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Utwórz policy
aws iam create-policy \
  --policy-name GitHubActionsECRECS \
  --policy-document file://ecr-ecs-policy.json

# Dołącz policy do użytkownika
aws iam attach-user-policy \
  --user-name github-actions-deploy \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/GitHubActionsECRECS

# Utwórz access keys
aws iam create-access-key --user-name github-actions-deploy
```

## Workflow: deploy.yml

Automatycznie:
- Buduje obraz Docker dla platformy linux/amd64
- Wypycha obraz do ECR
- Aktualizuje ECS service z nowym deploymentem

### Trigger:
- Push do brancha `main` lub `master`
- Ręczne uruchomienie (workflow_dispatch)
