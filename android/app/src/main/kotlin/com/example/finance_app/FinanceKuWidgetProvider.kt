// android/app/src/main/kotlin/com/financeku/app/FinanceKuWidgetProvider.kt
package com.financeku.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class FinanceKuWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Ambil data yang disimpan Flutter via home_widget
        val widgetData = HomeWidgetPlugin.getData(context)

        val balance = widgetData.getString("total_balance", "Rp 0") ?: "Rp 0"
        val income = widgetData.getString("monthly_income", "Rp 0") ?: "Rp 0"
        val expense = widgetData.getString("monthly_expense", "Rp 0") ?: "Rp 0"
        val todayExpense = widgetData.getString("today_expense", "Rp 0") ?: "Rp 0"
        val monthName = widgetData.getString("month_name", "") ?: ""
        val todayStr = widgetData.getString("today_str", "") ?: ""
        val lastUpdate = widgetData.getString("last_update", "--:--") ?: "--:--"

        // Cek apakah ini small atau medium widget berdasarkan options
        val info = appWidgetManager.getAppWidgetInfo(appWidgetId)
        val isSmall = info?.minWidth ?: 250 < 200

        val views = if (isSmall) {
            buildSmallWidget(context, balance, todayExpense, todayStr)
        } else {
            buildMediumWidget(context, balance, income, expense, todayExpense, monthName, lastUpdate)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun buildSmallWidget(
        context: Context,
        balance: String,
        todayExpense: String,
        todayStr: String
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_small)

        views.setTextViewText(R.id.widget_balance, balance)
        views.setTextViewText(R.id.widget_today_expense, todayExpense)
        views.setTextViewText(R.id.widget_today_label, "📅 $todayStr")

        // Tap pada widget → buka app
        setOpenAppPendingIntent(context, views, R.id.widget_balance)

        // Tap tombol + → buka add transaction
        setAddTransactionPendingIntent(context, views)

        return views
    }

    private fun buildMediumWidget(
        context: Context,
        balance: String,
        income: String,
        expense: String,
        todayExpense: String,
        monthName: String,
        lastUpdate: String
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_medium)

        views.setTextViewText(R.id.widget_balance, balance)
        views.setTextViewText(R.id.widget_income, income)
        views.setTextViewText(R.id.widget_expense, expense)
        views.setTextViewText(R.id.widget_today_expense, todayExpense)
        views.setTextViewText(R.id.widget_month, monthName)
        views.setTextViewText(R.id.widget_last_update, "Update $lastUpdate")

        // Tap widget → buka app
        setOpenAppPendingIntent(context, views, R.id.widget_balance)

        // Tap + → buka add transaction
        setAddTransactionPendingIntent(context, views)

        return views
    }

    private fun setOpenAppPendingIntent(context: Context, views: RemoteViews, viewId: Int) {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent ?: Intent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(viewId, pendingIntent)
    }

    private fun setAddTransactionPendingIntent(context: Context, views: RemoteViews) {
        // Deep link ke add transaction screen
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("financeku://add_transaction")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val pendingIntent = PendingIntent.getActivity(
            context, 1, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Set pada tombol + di kedua layout
        try {
            views.setOnClickPendingIntent(R.id.widget_add_btn, pendingIntent)
        } catch (e: Exception) {
            // small widget tidak punya widget_add_btn dengan ID tersebut
        }
    }
}

// Widget Medium Provider (terpisah agar bisa ditambah secara independen)
class FinanceKuWidgetMediumProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_medium)

            views.setTextViewText(R.id.widget_balance,
                widgetData.getString("total_balance", "Rp 0") ?: "Rp 0")
            views.setTextViewText(R.id.widget_income,
                widgetData.getString("monthly_income", "Rp 0") ?: "Rp 0")
            views.setTextViewText(R.id.widget_expense,
                widgetData.getString("monthly_expense", "Rp 0") ?: "Rp 0")
            views.setTextViewText(R.id.widget_today_expense,
                widgetData.getString("today_expense", "Rp 0") ?: "Rp 0")
            views.setTextViewText(R.id.widget_month,
                widgetData.getString("month_name", "") ?: "")
            views.setTextViewText(R.id.widget_last_update,
                "Update ${widgetData.getString("last_update", "--:--") ?: "--:--"}")

            // Open app on tap
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            val openPendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent ?: Intent(),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_balance, openPendingIntent)

            // Add transaction on + tap
            val addIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("financeku://add_transaction")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val addPendingIntent = PendingIntent.getActivity(
                context, 1, addIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_add_btn, addPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}