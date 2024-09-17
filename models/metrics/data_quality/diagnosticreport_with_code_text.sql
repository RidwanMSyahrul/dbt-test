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
      "description": "Proportion of DiagnosticReport resources that contain a non-empty code.text",
      "short_description": "DR with code.text",
      "primary_resource": "DiagnosticReport",
      "primary_fields": ['code.text'],
      "secondary_resources": [],
      "calculation": "PROPORTION",
      "category": "Data completeness",
      "metric_date_field": "issued",
      "metric_date_description": "Diagnostic Report issued date",
      "dimension_a": "status",
      "dimension_a_description": "The report status  (preliminary | final | amended | entered-in-error +)",
      "dimension_b": "category",
      "dimension_b_description": "The service category of the diagnostic report",
    }
) -}}

{%- set metric_sql -%}
    SELECT
      id,
      {{- metric_common_dimensions() }}
      status as status,
      COALESCE({{ fhir_dbt_utils.code_from_codeableconcept(
        'category',
        'https://g.co/fhir/harmonized/diagnostic_report/category',

      ) }},
      {{ fhir_dbt_utils.code_from_codeableconcept(
        'category',
        'http://snomed.info/sct,'
      ) }},
       {{ fhir_dbt_utils.code_from_codeableconcept(
        'category',
        'http://terminology.hl7.org/CodeSystem/v2-0074,'
      ) }},
       {{ fhir_dbt_utils.code_from_codeableconcept(
        'category',
        'http://loinc.org,'
      ) }}, 'Undefined')
       AS category,
      {{ fhir_dbt_utils.has_value('code.text') }} AS has_code_text
    FROM {{ ref('DiagnosticReport') }} AS C
{%- endset -%}

{{ calculate_metric(
    metric_sql,
    numerator = 'SUM(CAST(has_code_text AS '~fhir_dbt_utils.type_long()~'))',
    denominator = 'COUNT(id)'
) }}