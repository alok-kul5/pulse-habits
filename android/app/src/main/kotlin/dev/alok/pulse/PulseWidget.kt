package dev.alok.pulse

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

/**
 * The home-screen widget: today's habits, the perfect-day streak and a
 * seven-week heatmap. The app writes plain values through home_widget
 * (see lib/platform/widget_sync.dart); this draws them. Tapping a habit
 * opens Pulse with pulse://tick/<id>, which ticks it with the full
 * check-off animation.
 */
class PulseWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, build(context, widgetData))
        }
    }

    private fun build(context: Context, data: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.pulse_widget)
        val density = context.resources.displayMetrics.density

        val due = data.getInt("due", -1)
        val done = data.getInt("done", 0)
        views.setTextViewText(R.id.count, if (due < 0) "Open Pulse" else "$done/$due today")
        views.setTextViewText(R.id.streak, "🔥 ${data.getInt("streak", 0)}")
        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("pulse://open")),
        )

        val rows = intArrayOf(R.id.row0, R.id.row1, R.id.row2, R.id.row3)
        val dots = intArrayOf(R.id.dot0, R.id.dot1, R.id.dot2, R.id.dot3)
        val names = intArrayOf(R.id.name0, R.id.name1, R.id.name2, R.id.name3)
        val habits = try {
            JSONArray(data.getString("habits", "[]"))
        } catch (e: Exception) {
            JSONArray()
        }
        for (i in rows.indices) {
            if (i >= habits.length()) {
                views.setViewVisibility(rows[i], View.GONE)
                continue
            }
            val h = habits.getJSONObject(i)
            val isDone = h.optBoolean("done")
            views.setViewVisibility(rows[i], View.VISIBLE)
            views.setTextViewText(names[i], h.optString("name"))
            views.setTextColor(names[i], if (isDone) INK3 else INK)
            views.setImageViewBitmap(dots[i], dot(h.optLong("color").toInt(), isDone, density))
            views.setOnClickPendingIntent(
                rows[i],
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("pulse://tick/${Uri.encode(h.optString("id"))}"),
                ),
            )
        }

        views.setImageViewBitmap(R.id.heat, heatmap(data.getString("heat", "") ?: "", density))
        return views
    }

    /** A ring in the habit's colour, filled with a tick once it is done. */
    private fun dot(color: Int, done: Boolean, density: Float): Bitmap {
        val px = (16 * density).toInt()
        val b = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
        val c = Canvas(b)
        val r = px / 2f
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }
        if (done) {
            c.drawCircle(r, r, r, p)
            val tick = Path().apply {
                moveTo(px * .28f, px * .52f)
                lineTo(px * .44f, px * .68f)
                lineTo(px * .74f, px * .36f)
            }
            c.drawPath(tick, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = NIGHT
                style = Paint.Style.STROKE
                strokeWidth = 2.2f * density
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
            })
        } else {
            p.style = Paint.Style.STROKE
            p.strokeWidth = 2f * density
            c.drawCircle(r, r, r - p.strokeWidth, p)
        }
        return b
    }

    /** Seven columns of seven days, Monday at the top, ember for full days. */
    private fun heatmap(levels: String, density: Float): Bitmap {
        val cell = 11 * density
        val gap = 3 * density
        val size = (7 * cell + 6 * gap).toInt()
        val b = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val c = Canvas(b)
        val p = Paint(Paint.ANTI_ALIAS_FLAG)
        val radius = cell * .28f
        for (w in 0 until 7) {
            for (d in 0 until 7) {
                val ch = levels.getOrNull(w * 7 + d) ?: '-'
                if (ch == ' ') continue
                p.color = when (ch) {
                    '0' -> RAISED
                    '1' -> mix(RAISED, EMBER, .32f)
                    '2' -> mix(RAISED, EMBER, .58f)
                    '3' -> mix(RAISED, EMBER, .8f)
                    '4' -> EMBER
                    else -> EMPTY
                }
                val x = w * (cell + gap)
                val y = d * (cell + gap)
                c.drawRoundRect(RectF(x, y, x + cell, y + cell), radius, radius, p)
            }
        }
        return b
    }

    private fun mix(a: Int, b: Int, t: Float): Int = Color.rgb(
        (Color.red(a) + (Color.red(b) - Color.red(a)) * t).toInt(),
        (Color.green(a) + (Color.green(b) - Color.green(a)) * t).toInt(),
        (Color.blue(a) + (Color.blue(b) - Color.blue(a)) * t).toInt(),
    )

    private companion object {
        val NIGHT = Color.parseColor("#0D0A14")
        val RAISED = Color.parseColor("#201A2B")
        val EMPTY = Color.parseColor("#14101C")
        val EMBER = Color.parseColor("#FF5A36")
        val INK = Color.parseColor("#F7F3FB")
        val INK3 = Color.parseColor("#7D748C")
    }
}
