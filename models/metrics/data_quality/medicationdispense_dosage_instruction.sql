{#
/* Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */
#}

{{ config(
    meta = {
      "description": "Proportion of medication dispenses with dosage instruction text recorded",
      "short_description": "MedDisp instruction recorded",
      "primary_resource": "MedicationDispense",
      "primary_fields": ['dosageInstruction.patientInstruction', 'dosageInstruction.text'],
      "secondary_resources": [],
      "calculation": "PROPORTION",
      "category": "Data completeness",
      "metric_date_field": "MedicationDispense.whenPrepared",
      "metric_date_description": "Date when the dispensed medication was packaged and reviewed",
    }
) -}}

{%- set metric_sql -%}
    SELECT
      {{- metric_common_dimensions() }}
      M.id,
      IF(
        NULLIF({{ fhir_dbt_utils.safe_offset("dosageInstruction", 0) }}.patientInstruction, '') IS NOT NULL
          OR NULLIF({{ fhir_dbt_utils.safe_offset("dosageInstruction", 0) }}.text, '') IS NOT NULL,
        1,
        0) AS has_dosage_text
    FROM {{ ref('MedicationDispense') }} AS M
{%- endset -%}

{{- calculate_metric(
    metric_sql,
    numerator = 'SUM(has_dosage_text)',
    denominator = 'COUNT(id)'
) -}}
