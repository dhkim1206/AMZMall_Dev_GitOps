#!/bin/bash
aws eks --region ap-northeast-2 update-kubeconfig --name amz-draw-dev-cluster

kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass amzdraw-ebs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'