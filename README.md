# Serve `meta-llama/Llama-3.2` models on Amazon EC2

Here are the steps to serve the [`meta-llama/Llama-3.2-11B-Vision-Instruct`](https://huggingface.co/meta-llama/Llama-3.2-11B-Vision-Instruct) on Amazon EC2 using the [`Hugging Face TGI inference`](https://huggingface.co/text-generation-inference) container.


1. SSH to your EC2 instance and install docker.

    ```{.bashrc}
    sudo apt-get update
    sudo apt-get install --reinstall docker.io -y
    sudo apt-get install -y docker-compose
    docker compose version
    ```

1. Clone this repo on your EC2 instance.

    ```{.bashrc}
    git clone https://github.com/dheerajoruganty/Huggingface-TGI-EC2.git
    ```

1. Place your Hugging Face token in file called `/tmp/hf_token.txt` on your EC2 instance. Make sure you have access to the [`Llama3.2 models`](https://huggingface.co/meta-llama/Llama-3.2-11B-Vision-Instruct) on Hugging Face.

1. SSH to your instance and run the following commands. Running the `deploy_model.sh` does the following:

    - Downloads the HF TGI container from Amazon ECR.
    - Start the container, this downloads the model from the Hugging Face hub.
    - Create an endpoint accessible as `127.0.0.1:8080` to serve the model.

    ```{.bashrc}
    cd llama3.2_on_ec2
    chmod +x deploy_model.sh
    # the container takes about 10-minutes to start
    ./deploy_model.sh
    ```

1. Wait for 10-minutes, and then verify that the container is running.

    ```{.bashrc}
    docker ps
    ```

    You should see an output similar to the following:

    ```{.bashrc}
    CONTAINER ID   IMAGE                                                                                                                       COMMAND                  CREATED          STATUS          PORTS                                       NAMES
    bb509f2e4bf9   ghcr.io/huggingface/text-generation-inference:2.4.0   "./entrypoint.sh --j…"   12 minutes ago   Up 12 minutes   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp   HuggingfaceTGI
    ubuntu@ip-172-31-20-174:~$ 
    ```

1. Now you are ready to run a `cURL` command to get inference from the model.
    
    Here is an example for text inference.    
 
    ```{.bashrc}
    curl 127.0.0.1:8080/generate \
        -X POST \
        -d '{ "inputs":"What is quantum gravity?", "parameters":{ "max_new_tokens":20 } }' \
        -H 'Content-Type: application/json' | jq
    ```

    The above command will generate an output similar to the following:

    ```{.bashrc}
    {
    "generated_text": " Quantum gravity is a theoretical framework in physics that aims to merge quantum mechanics and general relativity. Quantum"
    }
    ```

    You can use the same endpoint for multi-modal inference as well. Here we ask the model to describe an image.

    ```{.bashrc}
    curl -N 127.0.0.1:8080/generate \
         -X POST \
         -d '{"inputs":"![](https://tinyurl.com/48eathrw) What is this a picture of? Explain in detail.\n\n", "parameters": {"max_new_tokens":100, "seed": 42}}' \
         -H 'Content-Type: application/json' | jq
    ```

    The above command will generate an output similar to the following:

    ```plaintext
    {
    "generated_text": "This image is a logo for the \"FM Benchmarking Tool.\" The logo is a blue hexagon with a green outline. The words \"FM Benchmarking Tool\" are written in white text in the center of the hexagon. Below the text is a bar graph with five bars, each a different shade of blue. A red line runs through the bars, starting at the first bar and ending at the fifth bar. The background of the image is white."
    }
    ```
1. You can see traces from the serving container by running the following command:

    ```
    docker logs -f HuggingfaceTGI
    ```
  
    You should see an output similar to this:

    ```plaintext
    2024-11-03T14:51:27.393883Z  INFO generate{parameters=GenerateParameters { best_of: None, temperature: None, repetition_penalty: None, frequency_penalty: None, top_k: None, top_p: None, typical_p: None, do_sample: false, max_new_tokens: Some(100), return_full_text: None, stop: [], truncate: None, watermark: false, details: false, decoder_input_details: false, seed: Some(42), top_n_tokens: None, grammar: None, adapter_id: None } total_time="4.065504959s" validation_time="440.038965ms" queue_time="94.981µs" inference_time="3.625371193s" time_per_token="38.982485ms" seed="None"}: text_generation_router::server: router/src/server.rs:402: Success
    ```

