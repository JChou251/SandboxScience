<template>
    <Bar :data="data" :options="options" />
</template>

<script lang="ts">
import { defineComponent } from "vue";
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
  type ChartData
} from 'chart.js'
import { Bar } from 'vue-chartjs'
import * as chartConfig from "~/helpers/utils/chartConfig";

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale)

const options = chartConfig.options
const data = ref<ChartData<'bar'>>({
  datasets: []
})

onMounted(() => {
  setInterval(() => {
    data.value = chartConfig.randomData()
  }, 3000)
})

export default defineComponent({
    props: {
        store: {
            type: Object,
            required: true,
        }
    },
    setup(props, { emit }) {
        const particleLife = props.store

        return { particleLife }
    }
})
</script>

<style scoped>

</style>