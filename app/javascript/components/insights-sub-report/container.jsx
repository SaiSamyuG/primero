import { useEffect } from "react";
import PropTypes from "prop-types";
import { useParams } from "react-router-dom";
import { fromJS } from "immutable";
import take from "lodash/take";
import { useDispatch } from "react-redux";

import { getLoading, getErrors } from "../index-table/selectors";
import LoadingIndicator from "../loading-indicator";
import { useI18n } from "../i18n";
import { useMemoizedSelector } from "../../libs";
import { clearSelectedReport } from "../reports-form/action-creators";
import TableValues from "../charts/table-values";
import BarChartGraphic from "../charts/bar-chart";
import useOptions from "../form/use-options";
import { CHART_COLORS } from "../../config/constants";
import InsightsFilters from "../insights-filters";

import { getInsight } from "./selectors";
import { fetchInsight } from "./action-creators";
import namespace from "./namespace";
import { NAME } from "./constants";
import css from "./styles.css";

const Component = () => {
  const { id, subReport, moduleID } = useParams();
  const i18n = useI18n();
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(fetchInsight(id, subReport));

    return () => {
      dispatch(clearSelectedReport());
    };
  }, []);

  const errors = useMemoizedSelector(state => getErrors(state, namespace));
  const loading = useMemoizedSelector(state => getLoading(state, namespace));
  const insight = useMemoizedSelector(state => getInsight(state));

  const insightLookups = insight.getIn(["report_data", subReport, "lookups"], fromJS({})).entrySeq().toArray();

  const lookups = useOptions({ source: insightLookups });

  const loadingIndicatorProps = {
    overlay: true,
    emptyMessage: i18n.t("report.no_data"),
    hasData: !!insight.getIn(["report_data", subReport], false),
    type: namespace,
    loading,
    errors
  };

  const totalText = i18n.t("report.total");

  const reportData = insight
    .getIn(["report_data", subReport], fromJS({}))
    .filterNot((_value, key) => ["lookups"].includes(key))
    .groupBy(value => (Number.isInteger(value) ? "single" : "aggregate"));

  const buildInsightValues = (data, key) => {
    if (data === 0) return [];

    return data
      .map(value => {
        // eslint-disable-next-line camelcase
        const lookupValue = lookups[key].find(lookup => lookup.id === value.get("id"))?.display_text || value.get("id");

        return { colspan: 0, row: [lookupValue, value.get("total")] };
      })
      .toArray();
  };

  const buildChartValues = (value, valueKey) => {
    if (!value) return {};

    const data = value?.map(val => val.get("total")).toArray();

    return {
      datasets: [
        {
          label: totalText,
          data,
          backgroundColor: take(Object.values(CHART_COLORS), data.length)
        }
      ],
      labels: value
        .map(val => {
          const valueID = val.get("id");

          // eslint-disable-next-line camelcase
          return lookups[valueKey].find(lookup => lookup.id === valueID)?.display_text || valueID;
        })
        .toArray()
    };
  };

  const subReportTitle = key => i18n.t(["managed_reports", id, "sub_reports", key].join("."));

  const singleInsightsTableData = reportData
    .get("single", fromJS({}))
    .entrySeq()
    .map(([key, value]) => ({ colspan: 0, row: [subReportTitle(key), value] }))
    .toArray();

  return (
    <>
      <InsightsFilters moduleID={moduleID} id={id} subReport={subReport} />
      <LoadingIndicator {...loadingIndicatorProps}>
        <div className={css.subReportContent}>
          <div className={css.subReportTables}>
            <h2 className={css.description}>{i18n.t(insight.get("description"))}</h2>
            {singleInsightsTableData.length && (
              <>
                <h3 className={css.sectionTitle}>{subReportTitle("incidents")}</h3>
                <TableValues values={singleInsightsTableData} />
              </>
            )}
            {reportData
              .get("aggregate", fromJS({}))
              .entrySeq()
              .map(([valueKey, value]) => (
                <div key={valueKey} className={css.section}>
                  <h3 className={css.sectionTitle}>{subReportTitle(valueKey)}</h3>
                  <BarChartGraphic data={buildChartValues(value, valueKey)} showDetails />
                  <TableValues values={buildInsightValues(value, valueKey)} />
                </div>
              ))}
          </div>
        </div>
      </LoadingIndicator>
    </>
  );
};

Component.displayName = NAME;

Component.propTypes = {
  mode: PropTypes.string.isRequired
};

export default Component;
