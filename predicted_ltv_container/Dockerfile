FROM 065012729803.dkr.ecr.us-east-2.amazonaws.com/predicted_ltv_base_image

COPY . /usr/local/src/scripts
WORKDIR /usr/local/src/scripts
CMD ["Rscript", "pareto_ggg_production_single_dataset_final.R"]
