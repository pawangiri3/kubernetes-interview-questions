#!/usr/bin/env bash
# 1) Create an EMPTY repo named "kubernetes-interview-questions" at https://github.com/new (no README/license)
# 2) Run this script from the folder that contains the optimized README.md
set -e
git clone https://github.com/gauri17-pro/kubernetes-interview-questions.git
cd kubernetes-interview-questions
cp ../README.md ./README.md          # replace with the optimized README
git add README.md
git commit -m "Expand guide with AKS content, fix inaccuracies, add new topics"
git remote remove origin
git remote add origin https://github.com/pawangiri3/kubernetes-interview-questions.git
git branch -M main
git push -u origin main               # sign in with your GitHub username + Personal Access Token
