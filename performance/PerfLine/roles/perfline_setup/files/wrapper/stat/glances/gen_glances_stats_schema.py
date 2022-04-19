#!/usr/bin/env python3
#
#
# Copyright (c) 2022 Seagate Technology LLC and/or its Affiliates
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# For any questions about this software or licensing,
# please email opensource@seagate.com or cortx-questions@seagate.com.
#
# -*- coding: utf-8 -*-

import sys
import yaml
import argparse

OUT_FILENAME = "glances_stats_schema.yaml"


def parse_args():
    parser = argparse.ArgumentParser(prog=sys.argv[0],
                                     formatter_class=argparse.RawDescriptionHelpFormatter,
                                     description="""
gen_glances_stats_schema.py is a tool for generating yaml formatted config file that describes
which graphs and metrics will be generated by plot_glances_stats.py utility.
This utility uses yaml formatted template as input file. Template file is almost the same
like yaml schema for plot_glances_stats.py utility apart from that template file can be include
some special label. Those labels are used for transformation them into real values.

For example:
    'diskio_[DATA_VOLUMES]_write_count' metric in the template will be
    replaced to 'diskio_[dm-0,dm-3,dm-11,dm-16,dm-20]_write_count' metric in the result file.

    'percpu_[CPU_NR]_total' metric will be replaced to 'percpu_[0..47]_total' metric in the result file.

Output result of this utility is 'glances_stats_schema.yaml' file
that can be used by 'plot_glances_stats.py' script

Usage example:
    $ ./gen_glances_stats_schema.py -y ./glances_stats_schema.template.yaml
        -d "dm-14 dm-3 dm-0 dm-15 dm-9 dm-1 dm-11" -n "eno1 enp175s0f0 enp175s0f1 eno2 tap0" -c 48
    """)

    parser.add_argument("-y", "--yaml-schema", type=str, required=True,
                        help="yaml formatted schema of graphs and metrics")

    parser.add_argument("-d", "--data-volumes", type=str, required=True,
                        help="list of data volumes")

    parser.add_argument("-m", "--md-volumes", type=str, required=True,
                        help="list of metadata volumes")

    parser.add_argument("-n", "--net-ifaces", type=str, required=True,
                        help="list of network interfaces")

    parser.add_argument("-c", "--cpu-nr", type=int, required=True,
                        help="number of CPU")

    return parser.parse_args()


def process_metric_template(metric_name, mapping):
    result = metric_name

    for k in mapping.keys():
        template_part = f'[{k}]'
        if template_part in metric_name:
            if k == 'CPU_NR':
                template_val = '[0..{}]'.format(mapping[k] - 1)
            else:
                template_val = '[{}]'.format(','.join(mapping[k]))
            result = metric_name.replace(template_part, template_val)

    return result


def main():

    args = parse_args()
    template_path = args.yaml_schema
    data_volumes = args.data_volumes.split()
    mdv = args.md_volumes.split()
    network_ifaces = args.net_ifaces.split()
    cpu_nr = args.cpu_nr

    with open(template_path) as f:
        template = yaml.safe_load(f.read())

    mapping = dict()
    mapping['NETWORK_IFACES'] = network_ifaces
    mapping['DATA_VOLUMES'] = data_volumes
    mapping['METADATA_VOLUMES'] = mdv
    mapping['CPU_NR'] = cpu_nr

    for figure_desc in template['figures']:
        if 'USE_AS_TEMPLATE_FOR' in figure_desc['figure']:
            tmp = figure_desc['figure']['USE_AS_TEMPLATE_FOR']

            if tmp == "CPU_NR":
                start_end = {"start": 0, "end": cpu_nr}
                figure_desc['figure']['iterate_for'] = start_end
            else:
                figure_desc['figure']['iterate_by'] = mapping[tmp]

            del figure_desc['figure']['USE_AS_TEMPLATE_FOR']

        for column_desc in figure_desc['figure']['columns']:
            for graph_desc in column_desc['column']:
                metrics_processed = []

                for metric in graph_desc['graph']['metrics']:
                    processed_name = process_metric_template(metric, mapping)
                    metrics_processed.append(processed_name)

                    if processed_name != metric:
                        print('{} --> {}'.format(metric, process_metric_template(metric, mapping)))

                graph_desc['graph']['metrics'] = metrics_processed

    result = yaml.dump(template)

    with open(OUT_FILENAME, 'w') as f:
        f.write(result)


if __name__ == '__main__':
    main()
