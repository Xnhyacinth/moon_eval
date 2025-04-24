accelerate launch -m lm_eval --model hf \
    --model_args pretrained=deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B \
    --include_path math500/ \
    --tasks math500 \
    --output_path output \
    --log_samples \
    --batch_size 32 \

    